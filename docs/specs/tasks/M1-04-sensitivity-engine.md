# M1-04: The sensitivity engine

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Match the sensitivity rules, withhold files, and redact values, at write time and again on every response, so a secret cannot reach a tool response even if it reached the index.
- **Depends on:** M1-01. It can run beside M1-02 and M1-03.
- **Spec references:** [sensitivity-rules.md](../sensitivity-rules.md), sections 2 to 5, 7, 9, and 10; [sensitivity-rules.json](../sensitivity-rules.json); [config.md](../config.md), sections 3 and 4, for what a repository may add and may not switch off; [fixture/README.md](../fixture/README.md), section 6, for the planted placeholders.
- **Files and interfaces:**
  - `src/RepoRanger.Core/Sensitivity/`: `RuleSet` (the built-in rules from `sensitivity-rules.json` plus the rules configuration adds), `Matcher` (`RegexOptions.ECMAScript` with the portable subset, a timeout per rule, Shannon entropy where a rule asks for it), `Allowlist`, `Redactor` (`[REDACTED:<rule id>]`, byte offsets, line count unchanged), `ResponseFilter` (the pass over every tool response).
  - The engine takes text and returns spans. Nothing else in the core decides what is sensitive.
- **Out of scope:** the pseudonymization of author identities, which belongs to history in M3; the tool responses themselves, which arrive in M1-10 and call `ResponseFilter`.
- **Tests first:**
  - The conformance corpus of sensitivity-rules.md section 10: every default rule matches its own sample, and no rule matches another rule's near miss.
  - Redaction replaces each value with exactly its rule's marker, leaves the surrounding text alone, and does not change the line count, so every recorded span still points at the right line.
  - A file rule withholds the whole file: a file node with `extraction = 'skipped'`, `skip_reason = 'sensitive'`, no chunks, and no content in any response.
  - The allowlist wins over a pattern rule, and a value that is only entropy-suspicious below the threshold is left alone.
  - The response pass redacts a value written by an older rule set, without re-indexing.
  - `rules_version` is recorded; a bump marks the index for re-redaction as section 7 requires.
  - A repository configuration that disables a built-in rule is refused; one that adds a rule is honoured.
- **Verification step:** `dotnet test --filter Sensitivity` passes, and one test prints the corpus table — rule, sample, marker — matching the M0 verification, plus the slowest rule's time on the one-megabyte adversarial input, which must stay under a second (it measured 307 ms in M0).
- **Done when:** the verification step passes, the tests are committed, and the review has no open correctness findings.
