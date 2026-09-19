# Glossary

**Last updated:** 2026-09-19

Terms used across the RepoRanger docs, in alphabetical order.

| Term | Meaning |
| --- | --- |
| ADR | Architecture decision record: a short document capturing one decision, its context, and its consequences. See [decisions](decisions/README.md). |
| Adversarial validation | A second, independent model tries to falsify each finding before it is reported. |
| BYOK | Bring your own key: users configure their own model providers and API keys. |
| Bus factor | How many contributors a module depends on. A low number means knowledge is concentrated in few people. |
| Call site | The name of the callee in a call, as a syntax extractor reports it. A SCIP occurrence at a call site becomes a CALLS edge; any other occurrence becomes a REFERENCES edge. |
| Change coupling | Files or modules that tend to change in the same commits, which can reveal dependencies the code graph doesn't show. |
| Churn | How often a file or symbol changes over time. |
| Community | A cluster of files and symbols found by community detection over the dependency graph, independent of folder layout. The docs also call it a module (code sense). |
| Context packing | Building a token-budgeted bundle (a symbol, its neighbors, summaries, evidence) for one question instead of sending whole files or repositories to a model. |
| Coupling degree | How strongly two files are change-coupled: 2 × shared commits ÷ (commits of one + commits of the other), from 0 to 1. |
| Decayed churn | Churn weighted by recency, so old changes count less than recent ones; the churn factor in the hotspot score. |
| Deep analyzer | A language-native plugin for facts SCIP doesn't carry, such as DI registrations, endpoints, and ORM entities. P1 inventories first; analyzers only where P1 shows a need. |
| External symbol | A symbol defined outside the repository, such as a .NET base-library type or a member of a NuGet, npm, or PyPI package. The index stores the ones the code references, so their uses can be queried. |
| Extraction status | How fully a file was extracted: `scip`, `fallback`, `syntax` (refreshed after an edit, with SCIP re-resolution pending), `text` (inventory and full-text only), or `skipped` with a reason. |
| Extractor plugin | A plugin that feeds the index: a syntax extractor for a language, a SCIP indexer descriptor, or a manifest extractor for a package ecosystem. See the [plugin interface](specs/plugin-interface.md). Analyzer plugins for framework facts arrive in P1. |
| Fact base | Everything RepoRanger knows about a repository (code graph, history, artifacts, metrics), with provenance. Lenses query it instead of reading raw files. |
| Fallback extraction | Symbols and imports without call resolution, for projects a SCIP indexer can't build. They come from the language's syntax extractor alone, which uses tree-sitter by default ([ADR 0015](decisions/0015-any-parser-that-passes-the-fixtures.md)). Its import edges are `import-scoped` or `name-match`. |
| Fixture | A small repository kept inside RepoRanger's own repository, with known symbol and edge counts and one project that deliberately doesn't build; the accuracy oracle and the fallback test. |
| Golden sample | A hand-checked set of call edges (30 per language) used to measure extraction precision; enforced in CI. |
| Finding | A structured, evidence-backed result with a location, evidence, severity, confidence, and category, in a SARIF-style schema. |
| GraphRAG-lite | Community detection plus hierarchical summaries over the deterministic code graph, without LLM entity extraction. |
| Health report | What extraction missed: parse failures, unresolved symbols, skipped files, and degraded analyzers. |
| Hierarchical summaries | LLM summaries at the symbol, file, module, and repository levels, generated lazily and cached by content hash, model, and prompt version. |
| Hotspot | Code with high churn, high complexity, and low coverage; where fixes and tests pay off first. |
| Importance ranking | A PageRank-style score over the call graph that decides what goes into repo maps and summaries first. |
| Index | The stored fact base for one repository at one ref. In the Embedded profile it is a single SQLite file. |
| Index hash | An identifier for an index's content: the root of a SHA-256 Merkle tree with one leaf per file. The same commit, configuration, and extractor versions must produce the same hash. |
| Indexer descriptor | How to run one SCIP indexer: its languages, project patterns, tools, command, output, and timeout. See the [plugin interface](specs/plugin-interface.md#71-indexer-descriptors). |
| Lens | An analysis pass over the fact base (security, tests, observability, and so on) that runs within a token budget and emits findings. |
| Locator | A `path:line` target in an MCP call. It resolves to the innermost symbol whose span covers the line, or to the file. |
| Manifest extractor | The plugin that reads one package ecosystem's manifests and lockfiles, and returns projects, declared dependencies, and locked packages. |
| MCP | [Model Context Protocol](https://modelcontextprotocol.io/): the standard that lets coding agents call RepoRanger's queries as tools. |
| Model role | A named job for a model: `extract`, `triage`, `synthesize`, `verify`, or `embed`. Features ask for a role, not a specific model. |
| Module (product) | One of the eight feature groups, such as Module 1 — Ingest & Index. See [feature groups](feature-groups.md). |
| P0, P1, P2 | Delivery phases: P0 is the MVP; P1 comes after the MVP and before the first lens module; P2 comes after the first two lens modules exist. |
| Profile | A storage deployment shape: Embedded (a single file for a laptop, CI, or MCP) or Server (multi-user, for teams). |
| Provenance | Where a fact came from: file, line range, commit, and the extractor that produced it. Within an index, the commit is the indexed commit. |
| Redaction | Replacing a secret in stored text or in a response with `[REDACTED:<rule id>]`. Every line break is kept, so line numbers never move. See the [sensitivity rules](specs/sensitivity-rules.md). |
| Registry | The user's list of registered repositories and the settings that name executables, in `registry.toml` under the RepoRanger home. See [configuration](specs/config.md). |
| Renderer | Turns findings and summaries into outputs: documents, llms.txt or AGENTS.md files, and backlog items. |
| Resolution level | How an edge's target was identified: `resolved` exactly (by a compiler through SCIP, or by a structural fact such as containment, a manifest, or git history), `import-scoped` (unique within imported files), or `name-match` (a repo-wide guess). The weight, not the level, says how strong the link is. See [ADR 0012](decisions/0012-resolution-levels-for-every-edge.md). |
| Response budget | The most an MCP response may hold: 8,000 estimated tokens, counted as UTF-8 bytes ÷ 4. A longer answer is cut, marked `truncated`, and continued with a cursor. |
| SCIP | [Source Code Intelligence Protocol](https://github.com/scip-code/scip): a language-agnostic index format emitted by compiler-backed indexers such as scip-dotnet, scip-typescript, and scip-python. RepoRanger's primary extraction source. |
| SARIF | [Static Analysis Results Interchange Format](https://sarifweb.azurewebsites.net/), a standard JSON format for analysis results. |
| Sensitivity policy | Rules that keep secrets and credentials out of the index's stored text, every tool response, and, from P1, every LLM call. File-name rules withhold whole files, and secret-pattern rules redact matches. See the [sensitivity rules](specs/sensitivity-rules.md). |
| Snapshot, snapshot diff | An index of a specific ref, and the difference between two such indexes (P1). |
| Staleness check | On every MCP call, a comparison of the index with the working tree. Up to 20 changed files are refreshed within 2 seconds: the syntax pass and stored text are redone, and SCIP re-resolution waits for the next index run. Otherwise the response is flagged `stale` in its `_meta` block. |
| Storage capability | One part of the data-access contract: NodeStore, EdgeStore, TextIndex, SummaryStore, or VectorIndex. Its interfaces are specified with the Server profile ([ADR 0016](decisions/0016-storage-capabilities-with-the-server-profile.md)). |
| Symbol ID | A symbol's stable identifier: `path::kind::qualified-name`, plus a signature hash for C# overloads. External symbols use `ext:` and their SCIP symbol. See [ADR 0014](decisions/0014-symbol-id-scheme.md) and the [index schema](specs/index-schema.sql). |
| Syntax extractor | The plugin that runs the syntax pass for one language. Any parser that passes the golden fixtures may implement it ([ADR 0015](decisions/0015-any-parser-that-passes-the-fixtures.md)). |
| Syntax pass | The parse every code file gets, whether or not its project builds, run by the language's syntax extractor. It supplies declaration spans, kinds, names, parameters, doc comments, metrics, and call sites, and SCIP adds resolution on top. See [ADR 0013](decisions/0013-syntax-pass-on-every-code-file.md). |
| Withheld file | A file matched by a file-name rule, such as `.env`. It stays in the graph, but its text is never stored or returned. |
| `_meta` | The block on every MCP response: repository, indexed commit, index age, stale flag, schema version, index state, and freshness counts (refreshed, pending, and changed files). |
