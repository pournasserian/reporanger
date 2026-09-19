# Module 1 — Ingest & Index: MVP brief

**Status:** Accepted 2026-09-19, after the review of the same day; changes go through a decision record · **First drafted:** 2026-09-18

Related: [feature catalog](feature-catalog.md) (every Module 1 idea with its phase) · [design notes](design-notes.md) (draft technical sketch) · [decision records](../../decisions/README.md) · [landscape research](../../research/oss-landscape-2026-09.md)

## Purpose

The MVP proves that RepoRanger can assemble a precise, history-aware, evidence-backed fact base for a large polyglot repository at zero LLM cost, and expose it to coding agents through MCP and to later modules through one query set.

It is deliberately thin. Code structure is imported from compiler-backed SCIP indexes rather than parsed in-house ([ADR 0011](../../decisions/0011-scip-first-extraction.md)), because the [landscape research](../../research/oss-landscape-2026-09.md) shows that code-graph indexing is the most crowded category in the field, and that precision, not language count, is where the leaders win. RepoRanger's product is the lenses that read this fact base; Module 1 builds the smallest fact base they need.

Module 1 is the first of eight [feature groups](../../feature-groups.md): Ingest & Index, Documentation, Audit & Findings, Enhancement Recommendations, Test Quality, Observability & Logging, Backlog & Delivery, and the cross-cutting Platform layer.

## Scope

- **Languages:** C#, TypeScript/JavaScript, and Python through the SCIP indexers (scip-dotnet, scip-typescript, scip-python). Projects that don't build fall back to tree-sitter symbols and imports, without call resolution. All other files are inventoried with hashes and full-text only.
- **Sources:** local folders and any git URL; credentials are handled by git; one chosen branch, tag, or commit per index run.
- **Outputs:** one SQLite file per repository, a CLI, and an MCP server (stdio) with 14 tools, two resources, and a usage prompt, all backed by one query set.
- **Cost:** P0 makes no LLM calls. Summaries and the bring-your-own-key plumbing arrive in P1.
- **Delivery target:** the four demo repositories below plus an in-repo fixture, indexed end to end, with a published benchmark.

Demo repositories (chosen 2026-09-19; sizes are estimates from GitHub language byte counts and include tests). Each must build for its SCIP indexer: a successful restore for C#, a `tsconfig` for TypeScript, and a resolvable environment for Python.

| Repository | Role | Estimated size | Languages | License |
| --- | --- | --- | --- | --- |
| [dotnet/orleans](https://github.com/dotnet/orleans) | C# demo | ~860k LOC | C# 99% | MIT |
| [nestjs/nest](https://github.com/nestjs/nest) | TypeScript demo | ~110k LOC | TypeScript | MIT |
| [fastapi/fastapi](https://github.com/fastapi/fastapi) | Python demo | ~114k LOC | Python | MIT |
| [microsoft/agent-framework](https://github.com/microsoft/agent-framework) | Scale test | ~1.1M LOC | Python 57%, C# 40%, TypeScript 2% | MIT |
| Fixture, kept in this repository | Golden sample and fallback test | Small | C#, TypeScript, Python; one project that deliberately doesn't build | MIT |

## Out of scope

Anything that produces findings or documents belongs to later modules. The items below are deferred within Module 1 itself.

| Deferred item | Lands in |
| --- | --- |
| LLM summaries, model-role configuration, token and cost log | P1 |
| Symbol-level change history (P0 records history per file) | P1 |
| Ownership concentration, bus factor, contributor expertise map | P1 |
| Cognitive complexity | P1 |
| README and ADR files as document nodes | P1 |
| String-literal and annotation flagging, and the interface, config, logging, error-handling, authorization, and data-model inventories | P1 |
| Framework-level facts beyond what SCIP resolves (DI registrations, endpoints, ORM entities, middleware) | P1 |
| Full tree-sitter call extraction, if a language without a SCIP indexer ever needs it | P1 |
| Coverage, SARIF, and IaC ingestion; coverage also restores the coverage factor in the hotspot score | P1 |
| Host APIs (PR and issue enrichment), watch mode, webhooks, agent hooks and skills, HTTP transport | P1 |
| Multiple snapshots per repo and snapshot diff | P1 |
| Semantic (embedding) search; server profile (PostgreSQL); admin UI | P2 |
| Cross-repo analysis; markdown documentation layer | Later modules |

## P0 feature list

Twelve areas, all deterministic.

| Area | P0 capabilities |
| --- | --- |
| Repository sources | Local path; any git URL, with credentials handled by git; repo registry with default branch, last indexed commit, and index status |
| Discovery | `.gitignore` plus tool-level include/exclude; language, project/package, and monorepo detection; skip generated, vendored, minified, and binary files; size caps; skip report with reasons |
| Extraction (SCIP-first) | Run or ingest SCIP indexes: files, symbols with signatures and doc comments, imports, calls, references, and inheritance/implementation, resolved by the compiler. Fallback for projects that don't build: tree-sitter symbols and imports only, marked in the health report |
| Edge model | Every edge carries a type, a weight, provenance, and a resolution level: `resolved`, `import-scoped`, or `name-match` |
| Repository artifacts | Dependency manifests and lockfiles to a package graph with versions; test-to-code mapping by naming convention, imports, and test attributes |
| History (file level) | Commit graph with authors, dates, parents, and tags; file–commit links; commit-to-PR/issue references from messages; full history by default with a configurable window; author pseudonymization as an opt-in flag |
| History signals | Recency-weighted churn, age, change coupling, and bug-fix commit detection per file; hotspot score = decayed churn × complexity |
| Structure inference | Community detection to derive modules independent of folder layout; entry points; importance ranking (PageRank-style) over the call graph |
| Code metrics | Cyclomatic complexity, nesting depth, LOC, and parameter count per symbol |
| Index & retrieval | Graph queries: neighbors, impact with a depth cap, dependencies, tests-for, module drill-down, and history per node; ranked full-text search with filters; deterministic context packing within a token budget |
| Incremental & freshness | Content-hash re-indexing: only changed files are reparsed and only affected edges invalidated; writes are committed per batch, so an interrupted run resumes by rerunning; staleness check on every MCP call with a bounded automatic refresh; a `_meta` block (indexed commit, index age, stale flag) on every response |
| Exposure | CLI and MCP (stdio) over one query set: `index_repo`, `get_index_info`, `repo_map`, `get_module`, `find_symbols`, `get_symbol`, `get_neighbors`, `get_impact`, `get_dependencies`, `get_tests_for`, `get_hotspots`, `get_history`, `search`, `pack_context`. Every list tool accepts many targets, paginates, and has `include` flags. MCP resources for the repo map and index info, plus a usage prompt |
| Trust & governance | Provenance on every node and edge; stable symbol IDs (path, kind, name, signature hash); health report (parse failures, unresolved symbols, skipped files, fallback projects); sensitivity policy applied to every tool response, with file-name and secret-pattern rules; reproducible index with an index hash; `schema_version` with re-index on mismatch; importer and extractor plugin interface defined (published in P1); golden-sample accuracy check in CI |

## Retrieval and storage

The MVP needs two retrieval modes; summaries and semantic search are deferred ([ADR 0003](../../decisions/0003-retrieval-graph-fts-graphrag-lite.md)).

| Mode | Answers | MVP status |
| --- | --- | --- |
| Structural (graph) | What calls this, what depends on that, which tests reach it, impact of a change, which commits touched it | Required |
| Lexical (full-text) | Where an identifier, string, config key, or log message appears; ranked and filterable | Required |
| Hierarchical summaries | Symbol to file to module to repo, with module boundaries from community detection ("GraphRAG-lite", no LLM entity extraction) | P1, lazy and cached |
| Semantic (vectors) | Where a concept lives; what a module means to the business | P2 |

Storage is abstracted by capability, not by vendor: NodeStore, EdgeStore with `traverse(depth)`, TextIndex, SummaryStore (P1), and later VectorIndex. Adapters declare which capabilities they provide natively. The platform ships two profiles, Embedded and Server, and the MVP ships Embedded only ([ADR 0004](../../decisions/0004-storage-abstraction-by-capability.md)).

The Embedded engine is SQLite ([ADR 0005](../../decisions/0005-sqlite-for-mvp.md)): one file per repository holding nodes (with JSON attributes), edges with type, weight, provenance, and resolution level, a full-text index, and history tables. One-to-three-hop queries are indexed joins; deeper traversals are depth-capped recursive queries; community detection and importance ranking run in memory at index time and persist as node attributes. The file records its `schema_version`; in the MVP a mismatch triggers a re-index rather than a migration. PostgreSQL is the planned Server adapter; Neo4j, MongoDB, and others are optional community adapters.

## Non-functional requirements

- **Accuracy:** extraction precision of at least 90% on the golden sample, and every edge says how it was resolved.
- **Scale:** a repository of about 1M LOC and 20k files indexes on a laptop; a one-file change re-indexes in seconds.
- **Cost:** zero LLM calls in P0.
- **Freshness:** no MCP response is silently stale; it is refreshed within the configured bound or flagged.
- **Privacy:** nothing leaves the machine in P0, and secret or credential content never appears in a tool response.
- **Reproducibility:** the same commit and configuration produce an identical index with the same index hash.
- **Portability:** the index file can be copied, shared, and loaded without re-indexing.
- **Stack neutrality:** every contract (index schema, MCP tool surface, plugin interface, model-role config) is language-independent, so components can be implemented in C#, TypeScript, or Python. The reference implementation is C#/.NET ([ADR 0010](../../decisions/0010-dotnet-reference-implementation.md)).
- **Licensing:** the project and its in-process dependencies stay under permissive licenses (MIT or Apache-2.0); the SCIP indexers are Apache-2.0 and run as external processes; copyleft tools run only as optional external processes ([ADR 0007](../../decisions/0007-permissive-licensing.md)).

## Acceptance criteria

The MVP is done when all of the following hold on the fixture and the four demo repositories; the scale criteria apply to microsoft/agent-framework.

- [ ] Extraction precision is at least 90% on the hand-checked golden sample (30 call edges per language), enforced by the CI check.
- [ ] A full index of microsoft/agent-framework (~1.1M LOC, three languages), with default settings (full history), completes on a laptop with zero LLM calls; index time and file size are recorded.
- [ ] Changing one file and re-indexing completes in seconds, and only affected nodes and edges change. Killing the indexer midway and rerunning produces the same index.
- [ ] Every MCP response carries provenance and a `_meta` block. After a file is edited, the next call either refreshes within the configured bound or reports `stale`.
- [ ] `get_impact` on a top-ranked symbol, at the default depth cap, meets the p95 latency target set in M0 (an early check that the embedded store holds up).
- [ ] Index health and skip reports account for every file that was not fully extracted, including every project that fell back to tree-sitter.
- [ ] The sensitivity policy keeps secret and credential content out of every tool response, verified by a test.
- [ ] Re-indexing the same commit with the same configuration reproduces the same index hash.
- [ ] The index file can be copied to another machine and queried without re-indexing.
- [ ] A coding agent (Claude Code or similar) navigates an unfamiliar demo repo using only the MCP tools, resources, and usage prompt.
- [ ] A benchmark page reports accuracy, index time, and query latency on the demo repos against at least codebase-memory-mcp and CodeGraphContext, including the rows RepoRanger loses.

## Decisions (confirmed 2026-09-19)

Rows 1–8 started as assumptions in the first draft and now have answers. Rows 9–13 were decided when the docs were extracted and reviewed. Rows 12 and 13 were then refined by the review below.

| # | Topic | Decision | Changed from the draft? |
| --- | --- | --- | --- |
| 1 | History window | Full history by default. The window stays configurable per repo, by time or by commit count. | Yes. The draft proposed the last 24 months or 5,000 commits, deepened per module on demand. |
| 2 | Test-to-code mapping in P0 | Heuristic: naming conventions, imports, and test attributes. Coverage ingestion arrives in P1. | No |
| 3 | Author identity | Real names and emails are stored; pseudonymization is an opt-in flag. | No |
| 4 | Monorepos | The whole repo is indexed as one; community detection finds the projects; scoped indexing waits for P2. | No |
| 5 | Summary trigger | Lazy only; no eager pass after indexing. Applies from P1, when summaries arrive. | No |
| 6 | Non-parsed file types (YAML, JSON, SQL, shell) | Inventoried with hashes and full-text only; structured extraction waits for the P1 inventories. | No |
| 7 | MCP transport | Local stdio first; HTTP transport in P1. | No |
| 8 | Demo repositories | dotnet/orleans (C#), nestjs/nest (TypeScript), fastapi/fastapi (Python), microsoft/agent-framework (~1.1M LOC; Python, C#, TypeScript) for the scale test, plus an in-repo fixture with known counts. | Yes. The draft proposed one public repo per language and named none. |
| 9 | Index engine | Module 1 owns its schema and fact base rather than wrapping an existing indexer ([ADR 0009](../../decisions/0009-build-the-index-in-house.md)); code structure is imported from SCIP ([ADR 0011](../../decisions/0011-scip-first-extraction.md)). | New |
| 10 | Reference implementation | C#/.NET builds the first index engine; all contracts stay stack-neutral ([ADR 0010](../../decisions/0010-dotnet-reference-implementation.md)). | New |
| 11 | Impact query | A dedicated `get_impact(symbol, depth, direction)` tool returns transitive callers or dependents up to a depth cap; one-hop neighbors come from `get_neighbors`. | New |
| 12 | Summary roles | `extract` generates symbol and file summaries; `synthesize` generates module and repo summaries. Applies in P1, since review item 1 moved summaries out of P0. | New |
| 13 | Hotspot milestone | The hotspot score ships in M3 together with the history signals; the formula was changed by review item 13. | New |

## Review decisions (2026-09-19)

The MVP was reviewed against the current open-source field ([research](../../research/oss-landscape-2026-09.md)). Option B, a thin fact base, was chosen, and all 23 review items were decided as listed.

| Item | Decision |
| --- | --- |
| 1 | LLM summaries, model-role configuration, and the token/cost log move to P1; P0 makes no LLM calls. `repo_map` is structural; `pack_context` packs code and evidence only. |
| 2 | History is recorded per file in P0; symbol-level change records move to P1. |
| 3 | Bus factor, ownership concentration, and the contributor expertise map move to P1. |
| 4 | Cognitive complexity moves to P1; P0 metrics are cyclomatic complexity, nesting depth, LOC, and parameter count. |
| 5 | Sources are a local path or any git URL; nothing is GitHub-specific in P0. |
| 6 | "Resumable runs" is not a separate feature; incremental indexing with per-batch commits provides it. |
| 7 | Export/import is replaced by a `schema_version` in the file with re-index on mismatch; portability stays an acceptance criterion. |
| 8 | README and ADR document nodes move to P1. |
| 9 | Extraction is SCIP-first with a light tree-sitter fallback (symbols and imports only) for projects that don't build ([ADR 0011](../../decisions/0011-scip-first-extraction.md)). |
| 10 | Every edge carries a resolution level: `resolved`, `import-scoped`, or `name-match`. |
| 11 | A staleness check runs on every MCP call, with a bounded automatic refresh, and every response carries `_meta`. Watch mode stays P1. |
| 12 | The tool surface is 14 tools, batchable with pagination and `include` flags: `get_callers` and `get_callees` merge into `get_neighbors`; `get_file_outline` merges into `get_module`. |
| 13 | Hotspot score = recency-weighted churn × complexity; the coverage factor returns in P1 with coverage ingestion. |
| 14 | Acceptance adds a ≥90% golden-sample precision target, measured index time and size on agent-framework, and a `get_impact` p95 latency target set in M0. |
| 15 | The sensitivity policy applies to every tool response and adds secret-pattern rules to file-name rules. |
| 16 | An in-repo fixture with known symbol and edge counts and one deliberately non-building project joins the four demo repositories. |
| 17 | `get_history(node, limit)` is added: commits touching a file or module, with message, author, date, and PR/issue references. |
| 18 | `get_module(id)` is added: members, entry points, dependencies in and out, hotspots, and coupling partners of one community or file. |
| 19 | `get_index_info` is added: indexed commit, index hash, schema version, counts, health summary, staleness. |
| 20 | Symbol IDs are stable across re-indexing: path, kind, name, and a signature hash. |
| 21 | The MCP server exposes `repo_map` and index info as resources and ships a usage prompt. |
| 22 | A golden-sample extraction check runs in CI against the fixture. |
| 23 | A public benchmark page is a release deliverable, with the rows RepoRanger loses. |

**Risks to watch**

- **SCIP dependence:** the indexers are maintained by Sourcegraph, and a repo that doesn't build only gets the fallback. M1 measures how much of each demo repo resolves.
- **Full history:** file-level history is cheap, but M3 still measures indexing time on agent-framework with the default window.
- **Graph algorithms in .NET:** community detection and PageRank have no mature .NET library; Louvain is the fallback if Leiden proves too much work.

## Next: P1 preview

P1 turns the index from a precise code map into a repository fact base and lands before the first lens module.

- LLM summaries with the model-role configuration, bring-your-own-key, and the token and cost log.
- Symbol-level change history; ownership, bus factor, and the contributor expertise map; cognitive complexity; README and ADR document nodes.
- A tree-sitter pass for string literals and annotations, feeding the deterministic inventories: system interfaces (routes, gRPC, GraphQL, queues, jobs), configuration surface, logging and telemetry sites, error handling, authorization surface, data model with PII-looking fields, and self-declared debt (TODO/FIXME with age).
- Framework-level facts beyond SCIP (DI registrations, endpoints, ORM entities, middleware); coverage and SARIF ingestion; LLM history digests and candidate ADRs.
- Full sensitivity classification; watch mode, webhooks, and agent hooks and skills; host APIs for PR and issue enrichment; multiple snapshots with snapshot diff; the published importer and extractor plugin API; HTTP transport for MCP.

Module 2 (Documentation) is the first consumer and will define the markdown layer: generated docs as versioned, human-editable source of truth, with the index as a rebuildable cache ([ADR 0006](../../decisions/0006-markdown-for-humans-db-as-cache.md)).
