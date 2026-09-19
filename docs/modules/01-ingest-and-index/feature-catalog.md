# Module 1 — Ingest & Index: feature catalog

**Status:** P0 as revised by the review of 2026-09-19 ([MVP brief](mvp-brief.md)); P1 and later are planning intent · **Last updated:** 2026-09-19

This catalog lists every Module 1 capability and idea discussed so far, with its phase. The MVP brief is the short version; the catalog keeps the long tail so nothing gets lost.

**Phases:** P0 = MVP · P1 = after the MVP, before the first lens module · P2 = after the first two lens modules exist · Deferred = no plan yet.

## Base capabilities

### 1.1 Repository sources

| Capability | Phase | Notes |
| --- | --- | --- |
| Local path | P0 | |
| Any git URL, with credentials handled by git | P0 | Covers GitHub, Azure DevOps, GitLab, and Bitbucket clones (review item 5) |
| Repo registry: default branch, last indexed commit, index status | P0 | Many repos can be registered; each is indexed independently |
| Host APIs: PR and issue enrichment, webhooks | P1 | Behind one host interface (idea #1) |
| Plain folders without git | P2 | No history signals without git (idea #1) |
| Cross-repo links | Later module | See cross-repo mode under Platform in [feature groups](../../feature-groups.md) |

### 1.2 Discovery (all P0)

- `.gitignore` plus tool-level include/exclude rules.
- Detection of languages, projects and packages, and monorepo layout (several projects in one repo); minimal framework and build-system detection, enough to run the right SCIP indexer.
- Skip generated, vendored, minified, and binary files; configurable size caps; a skip report says what was skipped and why.

### 1.3 Extraction

SCIP-first, per [ADR 0011](../../decisions/0011-scip-first-extraction.md).

| Capability | Phase | Notes |
| --- | --- | --- |
| SCIP importer: files, symbols with signatures and doc comments, imports, calls, references, inheritance/implementation, resolved by the compiler | P0 | scip-dotnet, scip-typescript, scip-python (Apache-2.0), run as external processes or ingested from a pre-built index |
| Fallback for projects that don't build: tree-sitter symbols and imports only, no call resolution | P0 | Marked per project in the health report |
| Resolution level on every edge: `resolved`, `import-scoped`, `name-match` | P0 | Review item 10 |
| String literals and annotations flagged for later lenses (log calls, config keys, endpoints, secret patterns) | P1 | A tree-sitter pass that feeds the P1 inventories |
| Full tree-sitter call extraction for languages without a SCIP indexer | P1, if needed | |

### 1.4 Deep extraction

SCIP already provides resolved types and precise call graphs in P0. What remains is framework-level.

| Capability | Phase |
| --- | --- |
| Framework-level facts: DI registrations, HTTP endpoints, ORM entities, middleware | P1, with the inventories |
| Graceful degradation: when an indexer can't run, the fallback stands and the gap appears in the health report | P0 |
| Language-native analyzers (Roslyn, TypeScript compiler API, LibCST) for facts SCIP doesn't carry | P2, only where P1 shows a need |

### 1.5 Repository artifacts

| Capability | Phase | Notes |
| --- | --- | --- |
| Dependency manifests and lockfiles → package graph with versions | P0 | |
| Test-to-code mapping | P0 | Heuristic ([MVP decision 2](mvp-brief.md#decisions-confirmed-2026-09-19)) |
| YAML, JSON, SQL, and shell files | P0 inventory and full-text; structure in P1 | MVP decision 6 |
| README, ADRs, and other docs as document nodes | P1 | Module 2 defines how they link to code (review item 8) |
| Coverage reports (e.g., Cobertura, LCOV) | P1 | Restores the coverage factor in the hotspot score |
| SAST results (SARIF) | P1 | |
| IaC files | P1 | Deriving deployment topology is idea #14 (P2) |

### 1.6 History

History is the input most documentation generators ignore, and it feeds almost every later module ([why](#why-history-earns-its-cost)).

**1.6a Raw history**

| Capability | Phase | Notes |
| --- | --- | --- |
| Commit graph: commits, authors, dates, parents, tags; file–commit links | P0 | Full history by default (MVP decision 1) |
| Commit-to-PR/issue references from messages | P0 | |
| Configurable window; author pseudonymization | P0 | Pseudonymization is opt-in (MVP decision 3) |
| Symbol-level change records per commit: symbols added, changed, removed | P1 | Review item 2 |
| PR and issue enrichment through host APIs: title, description, review comments, labels | P1 | Input for the P1 history digests |
| Branches and releases as first-class history data | P1 | Pairs with snapshots (P1) |

**1.6b History signals (deterministic, no LLM)**

| Capability | Phase |
| --- | --- |
| Recency-weighted churn and age per file | P0 |
| Change coupling: files and modules that change together | P0 |
| Bug-fix commit detection from messages and labels (fix, bug, hotfix, revert) | P0 |
| Hotspot score = decayed churn × complexity (review item 13); coverage factor in P1 | P0 |
| Ownership concentration, bus factor, contributor expertise map | P1 |
| The commits that introduced each detected bug | P2 |
| Velocity and refactoring trends over time | P2 |
| Dependency version history: when packages were bumped and how far they lag | P2 |

**1.6c History digests (LLM, lazy, cached): P1**

- Hierarchical summaries by module and time window (month, quarter, release): what changed and why, built from commit messages, PR descriptions, and symbol-level diffs, never full patches.
- Decision archaeology: past architectural decisions and their rationale, inferred from PR discussions, become candidate ADRs for the Documentation module.
- Recurring pain areas: modules with repeated fixes, reverts, or contentious PR threads.
- Module evolution narratives for onboarding and business docs.

Cost guardrails: raw history is deterministic and cheap; digests are lazy, per module and time window, and cached by commit-range hash; new commits only extend the latest window.

#### Why history earns its cost

- **Audits and bug reports:** prioritize by where bugs historically cluster, not only by static severity.
- **Tests:** high-churn, low-coverage modules are where tests pay off first.
- **Enhancements:** change coupling exposes hidden dependencies and refactoring candidates the code graph can't see.
- **Backlog:** effort estimates from how long similar changes took, and routing by ownership.
- **Docs:** change logs and "why" context that static analysis can never produce.

### 1.7 Structure inference

| Capability | Phase |
| --- | --- |
| Community detection over the dependency graph → modules independent of folder layout | P0 |
| Entry points | P0 |
| Importance ranking (PageRank-style) over the call graph | P0 |
| Layer and boundary inference; hot paths | P2 |

### 1.8 Index & retrieval

| Capability | Phase |
| --- | --- |
| Graph queries: neighbors, impact (depth-capped), dependencies, tests-for, module drill-down, history per node | P0 |
| Ranked full-text search with filters (language, path, symbol kind) | P0 |
| Context packing (idea #28), deterministic and token-budgeted | P0 |
| Hierarchical summaries (symbol → file → module → repo): lazy, cached by content hash, with model and prompt version | P1 |
| Semantic search (embeddings), off until an embedding model is configured | P2 |
| Typed query DSL (idea #30) | P2 |

### 1.9 Incremental, freshness & scale

| Capability | Phase |
| --- | --- |
| Content-hash re-indexing: reparse changed files only; invalidate affected edges | P0 |
| Writes committed per batch, so an interrupted run resumes by rerunning (review item 6) | P0 |
| Staleness check on every MCP call with a bounded automatic refresh; `_meta` on every response (review item 11) | P0 |
| Bounded resource use per run; progress reporting | P0 |
| Community detection re-run only when the edge set changes beyond a threshold | P0 |
| Watch mode and webhook-triggered re-index (idea #32) | P1 |

Target: a ~1M LOC repository indexed with zero LLM calls.

### 1.10 Exposure

| Capability | Phase |
| --- | --- |
| One query set behind the CLI, the MCP server, and an internal API for later modules and the UI | P0 |
| 14 MCP tools, batchable, with pagination and `include` flags (review item 12) | P0 |
| MCP resources for the repo map and index info; a usage prompt (review item 21) | P0 |
| MCP over stdio | P0 |
| `schema_version` in the index file with re-index on mismatch; the file itself is the portable bundle (review item 7) | P0 |
| MCP over HTTP | P1 (MVP decision 7) |
| Agent hooks and skills (as GitNexus and codebase-memory-mcp ship) | P1 |
| Web UI | Platform module, later |

### 1.11 Admin, governance & quality

| Capability | Phase |
| --- | --- |
| Per-repo settings | P0 |
| Index health report, including fallback projects | P0 |
| Sensitivity policy on every tool response, with file-name and secret-pattern rules (review item 15) | P0 |
| Golden-sample extraction check in CI against the in-repo fixture (review items 16 and 22) | P0 |
| Public benchmark page at release (review item 23) | P0 |
| Model-role configuration file with bring-your-own-key | P1 |
| Token and cost log for summary generation | P1 |
| Admin UI for model roles | P2 |

## Brainstorm ideas #1–#35

Tags from the brainstorm: R = recommended for v1, O = optional (v1.5), D = defer. The phase column shows where each idea landed after MVP prioritization and the 2026-09-19 review.

| # | Idea | Tag | Phase | Notes |
| --- | --- | --- | --- | --- |
| 1 | Additional hosts behind one interface: Azure DevOps, GitLab, Bitbucket, plain folders | R | P0 clones, P1 APIs | Any git URL clones in P0; host APIs in P1; plain folders without git in P2 |
| 2 | Index any ref and keep N snapshots per repo; snapshot diff (new or removed symbols, endpoints, dependencies) | R | P0 basic, P1 full | P0 indexes one chosen ref; snapshots and diff in P1 |
| 3 | Scoped indexing of one project or subfolder | O | P2 | MVP decision 4 |
| 4 | Submodules and vendored forks indexed as linked repos | O | P2 | |
| 5 | System interface inventory: HTTP routes, gRPC/proto, GraphQL, message consumers and producers, scheduled jobs, CLI commands, OpenAPI specs | R | P1 | Feeds business docs and observability |
| 6 | Data model inventory: ORM entities, migrations, SQL schemas, DTOs → data dictionary, with PII-looking fields flagged | R | P1 | |
| 7 | Configuration surface: env vars, config keys, feature flags, secret references, and which code reads which key | R | P1 | |
| 8 | Logging and telemetry inventory: log calls (level, message template, structured fields), metric emits, trace spans | R | P1 | Raw material for Module 6 |
| 9 | Error-handling inventory: thrown and caught exceptions, custom exception types, swallowed catches, retry and timeout patterns | R | P1 | |
| 10 | Authorization surface: auth attributes, policies, and roles per endpoint; unauthenticated endpoints stand out | R | P1 | |
| 11 | Complexity metrics per symbol: cyclomatic, cognitive, nesting, LOC, parameter count | R | P0 except cognitive (P1) | Review item 4 |
| 12 | Self-declared debt: TODO/FIXME/HACK comments with age from blame | R | P1 | |
| 13 | I/O and concurrency markers per function: DB calls, external HTTP, file I/O, locks, async patterns | O | P2 | Input for the performance lens |
| 14 | Deployment topology: Dockerfiles, Kubernetes, Terraform/Bicep, CI pipelines | O | P2 | |
| 15 | Inter-service edges: outgoing HTTP clients, queue names, service names in config | O | P2 | |
| 16 | Clone detection by token hashing | O | P2 | |
| 17 | Dead-code candidates: no callers, unreferenced exports, unused config keys | O | P2 | |
| 18 | Domain vocabulary mining from identifiers, comments, and docs → glossary seed | O | P2 | For business docs |
| 19 | Notebooks, SQL scripts, shell scripts, and GitHub Actions as first-class content | D | Deferred | P0 still inventories them (MVP decision 6) |
| 20 | Third-party code and license-header detection inside source | D | Deferred | |
| 21 | Contributor expertise map per module | R | P1 | Review item 3 |
| 22 | In-flight work: open PRs and stale branches mapped to the modules they touch | O | P2 | So lenses don't recommend work already in progress |
| 23 | Issue tracker ingestion linked to code areas | O | P2 | |
| 24 | Provenance on every node: file, line range, commit | R | P0 | Every later finding must cite evidence |
| 25 | Index health report: parse failures, unresolved symbols, degraded analyzers | R | P0 | Also lists projects on the tree-sitter fallback |
| 26 | Sensitivity policy: classify files and enforce "never expose" rules at the index level | R | P0 on tool output, P1 full classification | Review item 15 |
| 27 | Reproducibility: same commit + same config → identical index, with an index hash | R | P0 | |
| 28 | Context packing: a token-budgeted bundle (symbol, neighbors, evidence) for a question or symbol | R | P0, deterministic | Summaries join the pack in P1 |
| 29 | Importance ranking (PageRank-style) for repo maps | R | P0 | |
| 30 | Typed query DSL for agents and power users | O | P2 | |
| 31 | Portable index bundles; pre-indexed demo repos | O | P0 | The SQLite file is the bundle; demo bundles ship at release |
| 32 | Watch mode locally; webhook-triggered re-index on push | R | P1 | The P0 staleness check covers the local case |
| 33 | Importer and extractor plugin API for community languages and frameworks | R | P0 design, P1 published | The main open-source growth lever |
| 34 | Extraction benchmarks on golden repos with known counts | O | P0 minimal | The in-repo fixture and CI check (review items 16 and 22) |
| 35 | Cross-repo package/version matrix | D | Deferred | Belongs to cross-repo work |

## Other phase assignments

- **P2:** semantic search (embeddings); language-native analyzers where P1 shows a need; PostgreSQL adapter (Server profile); admin UI for model roles.
- **Deferred:** Neo4j adapter.
