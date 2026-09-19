# Configuration

**Status:** Proposed · **Last updated:** 2026-09-19

Four contracts leave values to "configuration": the [sensitivity rules](sensitivity-rules.md), the test markers and indexer descriptors in the [plugin interface](plugin-interface.md), the refresh bound in the [MCP contract](mcp-meta.json), and the history window and discovery limits in the [index schema](index-schema.sql). This file says where those values live, how the layers combine, what the defaults are, and which of them shape the index.

The files are TOML 1.0 ([ADR 0017](../decisions/0017-toml-for-configuration-and-golden-files.md)), and their shape after parsing is [config.schema.json](config.schema.json). RepoRanger's TOML files use no date or time values, so the data maps onto the JSON model exactly.

## 1. Files

| File | Holds | Written by |
| --- | --- | --- |
| `<home>/registry.toml` | Registered repositories, user-wide defaults, and every setting that names an executable | The user, and the CLI's register command |
| `<repo>/.reporanger.toml` | Settings a team shares through the repository: discovery, test markers, extra sensitivity rules | The team, committed |
| `<home>/indexes/<name>.db` | The index of a repository, unless `index_path` says otherwise | RepoRanger |
| `<home>/clones/<name>/` | The working copy of a repository registered by URL | RepoRanger |

`<home>` is `REPORANGER_HOME` when set. Otherwise it is `%LOCALAPPDATA%\RepoRanger` on Windows, `~/Library/Application Support/RepoRanger` on macOS, and `$XDG_DATA_HOME/reporanger`, or `~/.local/share/reporanger`, elsewhere.

Every file starts with `version = 1`. A file with another version is refused with `invalid_argument`, naming the file.

## 2. Layers

Later layers win:

1. The built-in defaults in this file.
2. `defaults` in `registry.toml`.
3. The repository's `.reporanger.toml`.
4. The repository's `settings` in `registry.toml`.
5. Command-line options and environment variables.

Merging follows two rules:
- **Tables** merge key by key.
- **Arrays** accumulate from the bottom layer up, keeping order and dropping duplicates. So a repository's excludes and a user's excludes both apply.

Only `sensitivity.disable` removes anything, and it names default rule ids.

## 3. What a repository may not set

`.reporanger.toml` comes from a repository, which may be someone else's. It may not:
- name executables, so no `plugins` and no `indexers`
- turn off sensitivity rules, so no `sensitivity.disable`
- register repositories or pick the default one
- decide where indexes live

Those live in `registry.toml`, which is the user's own file. [config.schema.json](config.schema.json) enforces the split: `repo_file` allows the shared settings only.

## 4. Settings

| Key | Type | Default | Shapes the index |
| --- | --- | --- | --- |
| `discovery.include` | globs | empty, meaning every discovered file | yes |
| `discovery.exclude` | globs | empty, added to the built-in exclusions | yes |
| `discovery.max_file_bytes` | integer | 1048576 | yes |
| `discovery.follow_symlinks` | boolean | false | yes |
| `history.window` | `"full"`, `{ days = N }`, or `{ commits = N }` | `"full"` | yes |
| `history.pseudonymize` | boolean | false | yes |
| `freshness.refresh_max_files` | integer | 20 | no |
| `freshness.refresh_max_seconds` | number | 2 | no |
| `tests.attributes` | strings | empty, added to the built-in markers | yes |
| `tests.file_patterns` | globs | empty | yes |
| `tests.base_classes` | strings | empty | yes |
| `sensitivity` | user rules | empty | yes |
| `scip.prebuilt` | manifest path to index file | empty | yes |

Registry-only keys: `default_repo`, `repos`, `defaults`, `pseudonymization.key_env` (default `REPORANGER_PSEUDONYM_KEY`), `plugins`, `indexers`.

## 5. Discovery defaults

Discovery walks the repository, honours `.gitignore`, and then applies these built-in rules. A file it skips still becomes a file node, with `extraction = 'skipped'` and a reason.

| Reason | Default rule |
| --- | --- |
| `excluded` | `discovery.exclude` matched, or `discovery.include` is set and didn't match |
| `vendored` | Inside `node_modules/`, `vendor/`, `third_party/`, `bower_components/`, `packages/`, `.venv/`, `venv/`, `site-packages/`, `bin/`, `obj/`, `dist/`, `build/` |
| `generated` | A name like `*.g.cs`, `*.generated.*`, `*.designer.cs`, `*_pb2.py`, `*.pb.go`, `*.min.map`, or an `auto-generated` marker in the first 5 lines |
| `minified` | A name like `*.min.js` or `*.min.css`, or an average line longer than 500 bytes over a file above 50 KB |
| `binary` | A NUL byte in the first 8 KB |
| `too_large` | Bigger than `discovery.max_file_bytes` |
| `encoding` | Not decodable as UTF-8, and no byte-order mark says UTF-16 |

The `.git` directory is never walked. These lists are part of the contract, so two implementations skip the same files; `discovery.exclude` extends them.

## 6. The effective configuration

The settings that shape the index are written to `meta.config_json` as `effective_config` in [config.schema.json](config.schema.json), and `config_hash` is the SHA-256 of its RFC 8785 canonical JSON. It holds the merged discovery, history, test markers, sensitivity rules, and pre-built index paths.

It leaves out settings that don't change content: the refresh bound, index paths, the default repository, plugin commands, and indexer descriptors. Plugins and indexers still reach the index hash, because every node and edge names the extractor and its version.

`history.pseudonym_key_set` records whether a key was supplied, never the key. Two different keys produce different pseudonyms, which the history section's hash reflects.

## 7. Secrets

- The pseudonymization key comes from the environment variable named by `pseudonymization.key_env`. No file holds it.
- Git credentials stay with git, as the brief requires. A `source` URL with credentials in it is refused; the CLI's register command strips them and says so.
- Configuration files are not redacted, because they are not indexed content. Keep secrets out of them.

## 8. Examples

A repository's `.reporanger.toml`:

```toml
version = 1

[discovery]
exclude = ["docs/legacy/**", "**/*.snap"]
max_file_bytes = 2097152

[tests]
attributes = ["IntegrationFact"]
file_patterns = ["**/*.IntegrationTests.cs"]

[[sensitivity.pattern_rules]]
id = "acme-service-token"
description = "Acme internal service tokens"
pattern = 'acme_tok_[A-Za-z0-9]{32}'
secret_group = 0
case_insensitive = false
keywords = ["acme_tok_"]
```

A user's `registry.toml`:

```toml
version = 1
default_repo = "orleans"

[defaults.history]
window = { days = 730 }

[defaults.sensitivity]
disable = ["jwt"]

[pseudonymization]
key_env = "REPORANGER_PSEUDONYM_KEY"

[[repos]]
name = "orleans"
source = "https://github.com/dotnet/orleans"
ref = "main"

[[repos]]
name = "shop"
source = "C:/work/shop"

[repos.settings.history]
pseudonymize = true

[[plugins]]
name = "syntax-typescript"
command = ["node", "C:/tools/rr-syntax-ts/main.js"]
```

## 9. Versions

`version = 1` is this contract's version, and it is separate from the index's `schema_version`. A change that alters the meaning of a setting increments it, and the reader then refuses files it doesn't understand rather than guessing. While this document is Proposed, changes keep version 1.
