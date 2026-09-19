# Sensitivity rules

**Status:** Proposed · **Last updated:** 2026-09-19

This contract keeps secrets and credentials out of RepoRanger's index and out of every tool response, as the MVP brief requires. It defines:
- the rules that decide what counts as a secret
- how a match is redacted, and when a whole file is withheld
- where redaction runs
- how users extend the rules
- what the index reports about redaction

[sensitivity-rules.json](sensitivity-rules.json) holds the rule model as JSON Schema, and the default rules, which are normative.

It builds on:
- the [MVP brief](../modules/01-ingest-and-index/mvp-brief.md#non-functional-requirements): "secret or credential content never appears in a tool response"
- the [index schema](index-schema.sql): the `sensitivity` column, redaction of every free-text column, `attrs.redactions`
- the [MCP contract](mcp-meta.json): the response pass

## 1. What is protected

Redaction applies to the text RepoRanger stores or returns:
- the stored text of files (`chunks.text`)
- the signatures and doc comments of symbols
- commit messages
- diagnostic and error messages

Identifiers, names, paths, and the graph's structure are never redacted. They carry no secret content, and IDs have to round-trip.

Syntax extractors and SCIP indexers read the unredacted text, because extraction needs the real code (plugin interface, section 2). Nothing they produce is stored as text without going through the rules.

## 2. Rules

The effective rule set is the defaults in [sensitivity-rules.json](sensitivity-rules.json), minus the default rules the configuration disables, plus the rules the configuration adds (section 8). A rule id may appear only once in the effective set. The order is the defaults' file order, then the user rules in configuration order.

- **File rule:** withholds every file whose repository-relative path matches one of its `globs` and none of its `exclude` globs. Globs match case-sensitively: `*` stays within one directory, `**` spans directories (so `**/.env` also matches `.env` at the root), and `?` matches one character.
- **Pattern rule:** finds secrets in text. It has a regex `pattern` in the portable subset (section 3); a `secret_group`, the capture group holding the secret (0 means the whole match); a `case_insensitive` flag; lowercase `keywords`; and optionally `min_entropy`. Every match contains at least one keyword, ignoring case, so a text without any keyword may skip the rule.
- **Allowlist:** value patterns (matched against a secret's value, ignoring case), path globs, and the `repeated_character` switch. A value that the allowlist accepts is not redacted. A file whose path matches an allowlisted glob is exempt from every rule, file rules included.

The defaults ship eight file rules and 26 pattern rules.

| Kind | Default rules |
| --- | --- |
| File rules (withhold) | `.env` files (templates excluded), private key and PEM files, SSH keys, key stores, credential files of common tools, Terraform state, kubeconfig, files named as secret stores, VPN profiles |
| Pattern rules (redact) | Private key blocks; AWS access key IDs and secret keys; GitHub, GitLab, Slack, Stripe, Google, OpenAI, Anthropic, npm, PyPI, NuGet, SendGrid, DigitalOcean, Vault, Docker Hub, and age keys and tokens; Slack webhooks; Azure storage keys and SAS signatures; JSON Web Tokens; passwords in URLs; passwords in connection strings; generic quoted secret assignments |
| Allowlist | Values made of one repeated character; values containing `example`, `sample`, `dummy`, `placeholder`, `changeme`, `redacted`, `your-`, `insert-`, or `replace-me`; references such as `${X}`, `{{X}}`, `$(X)`, `%(X)`; `<angle-bracket>` placeholders; values made only of `x`, `*`, `#`, `.`, `_`, `-`; bare placeholder words such as `password`, `secret`, `token`, `test`, `null`; lowercase identifiers such as `access_token` or `refresh-token`. No path is exempt, so test keys and the fixture's planted secrets are redacted like any other |

## 3. The portable regex subset

A pattern may use only syntax that .NET, JavaScript, Python, and RE2 all read the same way:
- literals and escapes
- character classes, including negated classes and ranges
- `\d`, `\w`, `\s`, and their negations, `\b`, and `.`
- `^` and `$`
- alternation, `(...)` numbered groups, `(?:...)` groups
- greedy and lazy quantifiers, with every `{m,n}` bound at 10,000 or less

It may not use:
- lookahead or lookbehind
- backreferences
- named groups
- inline flags such as `(?i)`
- atomic groups or possessive quantifiers
- Unicode property classes
- `\A`, `\z`, `\Z`, or `\G`

Case-insensitive matching is the rule's `case_insensitive` field.

Engines run the patterns with the settings that give these features the same meaning everywhere:
- Patterns see the whole text of a file (LF line endings) or of one field.
- `^` and `$` match at line boundaries.
- `.` doesn't match a newline; `[\s\S]` does.
- `\b`, `\d`, `\w`, and `\s` are ASCII-only.

| Engine | Options |
| --- | --- |
| .NET | `RegexOptions.Multiline \| RegexOptions.ECMAScript`, plus `IgnoreCase` |
| JavaScript | flags `gm`, plus `i`; `d` to read group offsets |
| Python | `re.MULTILINE \| re.ASCII`, plus `re.IGNORECASE` |

## 4. Redaction

1. **Find.** For each pattern rule in order, find its matches from left to right, never overlapping each other. Take the span of `secret_group`, and skip a match whose group didn't take part.
2. **Filter.** Drop spans whose value the allowlist accepts. For rules with `min_entropy`, drop spans whose Shannon entropy is below it. The entropy is `-Σ p(c) × log2 p(c)`, summed over the distinct characters `c` of the value, where `p(c)` is `c`'s share of the value's characters.
3. **Merge.** Sort the remaining spans by start and merge spans that overlap. A merged span takes the rule of its earliest span; on a tie, the rule listed first wins.
4. **Replace.** Replace each merged span with `[REDACTED:<rule id>]` followed by one LF for each line break inside the span. The marker stays on the span's first line. Text before and after the span is kept, so the file keeps its line count and every line keeps its number.

For example, `Password=Pa55-word-123;` becomes `Password=[REDACTED:connection-string-password];`. A private key block on lines 10 to 36 becomes the marker on line 10 and 26 lines that lost their key material.

**File status.** The file's `sensitivity` column records the outcome:
- `withheld`: a file rule matched. The file keeps its nodes, edges, history, and hashes, but it stores no chunks, and its symbols have no signature or doc comment.
- `redacted`: at least one span was replaced.
- `none`: nothing matched.

## 5. Where redaction runs

- **Write time.** Every free-text column is redacted before it is written (section 1, and the index schema's conventions). A withheld file's text is never stored at all.
- **Response time.** Before a result leaves the server, the current rules run again over every piece of text of the kinds in section 1, wherever it appears. That includes snippets, signatures, doc comments, commit subjects and bodies, search text, `pack_context` sections, and error and diagnostic messages. Identifiers, names, and paths pass unchanged. The same applies to resources and to error results. So a rule added after the index was built protects answers at once.
- **LLM calls, from P1.** Text sent to a model comes from redacted stored text, or passes the same redaction first. Withheld files are never sent. P1 may add stricter policies for models, such as excluding paths, but never weaker ones.

## 6. Tools and agents

- A `[REDACTED:<rule id>]` marker stands for a secret. No tool can recover its value, and agents shouldn't try (the usage prompt says so).
- `search` never returns text from withheld files, and `get_symbol` returns no snippet for their symbols.
- `pack_context` lists a withheld file's symbols in `omitted` with reason `withheld`.

## 7. Versions and re-redaction

- **Versions.** The defaults carry `rules_version`, 1 for this file. While this document is Proposed, changes keep version 1, as with the other contracts. After that, any change to a default rule increments it.
- **Configuration.** The effective rule set is recorded in `meta.config_json`: `rules_version`, the disabled ids, and the user's rules and allowlist entries. That puts it inside `config_hash` and the index hash.
- **Re-redaction.** When an index run finds that the effective rule set differs from the one recorded, it rewrites every file's stored text under the new rules. It reads each file again from the working tree when the content hash still matches, and doesn't re-extract anything. Until that run, the response pass applies the new rules.

## 8. Configuration

A repository's [configuration](config.md) may hold a `user_rules` object, as `$defs/user_rules` in [sensitivity-rules.json](sensitivity-rules.json) defines:
- more file rules and pattern rules
- more allowlist values and paths
- `disable`: ids of default rules to turn off

A default rule can be turned off only by naming its id, and only in the user's own registry file, never in a repository's `.reporanger.toml` ([configuration](config.md), section 3). The health report lists every disabled rule (section 9).

## 9. Reporting

- **Per file.** Each file node's `attrs.redactions` counts its redactions by rule id, one per merged span, under the rule that span took. It never holds values.
- **Per index.** `get_index_info` reports `health.sensitivity`: the rules version, the number of withheld files and redacted files, the redaction counts by rule, and the disabled default rules.
- **Later use.** The Audit & Findings module can start from these counts, since they show where secrets sit without exposing them.

## 10. Conformance

- **Defaults.** Every default rule is tested in .NET, JavaScript, and Python. All three must find the same spans on the same test corpus, and no rule may take more than a second on a 1 MB adversarial line.
- **Acceptance.** The MVP's acceptance test generates a fake secret for every default rule, and a placeholder for every allowlist entry. It plants them in a temporary copy of the fixture (M0 item 5), indexes that copy, and checks that no planted secret appears in any tool response and that every placeholder is left alone.
- **Keeping tokens out of this repository.** Test secrets are generated when the tests run, never committed, so this repository holds no token-shaped strings. Such strings could also trip GitHub's push protection.
