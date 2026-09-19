# Roadmap

**Status:** Proposed; milestones re-cut after the review of 2026-09-19 · **Last updated:** 2026-09-19

RepoRanger is in the design phase: documentation first, no code yet. The next step is Module 1's contracts (milestone M0), which are also written as documents.

## Where we are

- [x] Vision and the ten capabilities
- [x] Eight feature groups confirmed
- [x] Module 1 MVP brief, with its eight open assumptions confirmed
- [x] Core decisions recorded ([decision records](decisions/README.md))
- [x] Public repository with an MIT license, README, contribution guide, and docs
- [x] Module 1 design questions resolved: index built in-house, `get_impact` tool, summary roles, hotspots in M3
- [x] Pick the tech stack for the Module 1 reference implementation: C#/.NET ([ADR 0010](decisions/0010-dotnet-reference-implementation.md))
- [x] Pick the demo repositories: dotnet/orleans, nestjs/nest, fastapi/fastapi, and microsoft/agent-framework for the scale test ([MVP brief](modules/01-ingest-and-index/mvp-brief.md#scope))
- [x] Review the MVP against the current open-source field; option B (thin fact base) chosen and 23 review items decided ([MVP brief](modules/01-ingest-and-index/mvp-brief.md#review-decisions-2026-09-19), [research](research/oss-landscape-2026-09.md))
- [x] Development workflow decided: spec-driven per milestone, contract-first per interface, test-driven per task, adversarial review; plain in-repo specs ([development workflow](development-workflow.md)); a docs-phase `CLAUDE.md` is in place
- [x] M0 contracts under `docs/specs/` ([development workflow](development-workflow.md#specs-in-the-repository)):
  - [x] Index schema: [`index-schema.sql`](specs/index-schema.sql), with [ADR 0012](decisions/0012-resolution-levels-for-every-edge.md) (resolution levels), [ADR 0013](decisions/0013-syntax-pass-on-every-code-file.md) (syntax pass), and [ADR 0014](decisions/0014-symbol-id-scheme.md) (symbol IDs)
  - [x] MCP tools: [`mcp-meta.json`](specs/mcp-meta.json), the 14 tools in [`mcp-tools/`](specs/mcp-tools/), and [`mcp-usage.md`](specs/mcp-usage.md). `get_impact` defaults to depth 3 (maximum 6) with a p95 target of 300 ms, and the refresh bound is 20 files and 2 seconds
  - [x] Plugin interface: [`plugin-interface.md`](specs/plugin-interface.md) and [`plugin-facts.json`](specs/plugin-facts.json), including the syntax pass contract, with [ADR 0015](decisions/0015-any-parser-that-passes-the-fixtures.md) (any parser that passes the fixtures) and [ADR 0016](decisions/0016-storage-capabilities-with-the-server-profile.md) (storage capability interfaces move to the Server profile)
  - [x] Sensitivity rules: [`sensitivity-rules.md`](specs/sensitivity-rules.md) and [`sensitivity-rules.json`](specs/sensitivity-rules.json). They define the rule model, the defaults (8 file rules and 26 pattern rules), the `[REDACTED:<rule id>]` marker, and redaction at write time and on every response
  - [x] Configuration (added 2026-09-19): [`config.md`](specs/config.md) and [`config.schema.json`](specs/config.schema.json): the registry, per-repository settings, layering, discovery defaults, and the effective configuration behind `config_hash`, in TOML ([ADR 0017](decisions/0017-toml-for-configuration-and-golden-files.md))
  - [x] Fixture and golden-sample format: [`fixture/README.md`](specs/fixture/README.md), [`golden/golden.schema.json`](specs/golden/golden.schema.json), the three [`golden/<language>.toml`](specs/golden/csharp.toml) files, and a syntax conformance case per language under [`golden/syntax/`](specs/golden/syntax). The fixture itself is built by M1 (C#) and M3 (TypeScript, Python)
  - [x] M1 task specs: [`tasks/`](specs/tasks/README.md), eleven pages from M1-01 to M1-11 in dependency order, each naming the contracts it implements, the tests to write first, and the command that proves it works
- [ ] Reserve `reporanger` on npm, PyPI, and NuGet (all three were free on 2026-09-19)
- [ ] Set the GitHub About text and topics (text decided; see below)

## Module order

1. **Module 1 — Ingest & Index:** P0 (the MVP), then P1 before the first lens module.
2. **Module 2 — Documentation:** the next module to design, and the first consumer of the index.
3. **Everything else:** order not decided yet (see [open decisions](#open-decisions)).

## Module 1 milestones (proposed)

About 7–9 weeks, part-time. Each milestone ends in something demoable. The saving against the original plan comes from importing extraction instead of writing it, and from moving the LLM milestone to P1.

| Milestone | Scope | Estimate |
| --- | --- | --- |
| M0 — Contracts | Index schema (SQLite DDL) with resolution levels, symbol IDs, and `schema_version`; the 14 MCP tool shapes, `_meta`, resources, and the usage prompt; importer and extractor plugin interface; sensitivity rules format; configuration format; fixture repo and golden-sample format; the `get_impact` depth cap and latency target; the refresh bound. Written as files under `docs/specs/` before any engine code, plus the M1 task specs ([development workflow](development-workflow.md)) | 1 week |
| M1 — SCIP spike | Discovery; the syntax pass and the SCIP importer for C# (scip-dotnet); the SQLite writer; `repo_map`, `find_symbols`, and `get_symbol` over the CLI. Indexes dotnet/orleans; measures precision on the C# golden sample and index size and time. This is where reality can change the plan | 1–2 weeks |
| M2 — Graph & search | Edge model with resolution levels; `get_neighbors`, `get_impact` with a depth cap, `get_module`, `get_dependencies`; full-text index; community detection; importance ranking; complexity metrics; the golden-sample CI job; the deep-traversal check | 2 weeks |
| M3 — Languages & history | scip-typescript and scip-python importers with their syntax passes; the tree-sitter fallback; file-level history, decayed churn, coupling, bug-fix detection, and the hotspot score; test-to-code mapping; dependency manifests; `get_history`, `get_hotspots`, `get_tests_for`. Measures full-history indexing time on agent-framework | 2 weeks |
| M4 — MCP & freshness | All tools over stdio; resources and the usage prompt; the staleness check and `_meta`; content-hash incremental indexing with per-batch commits; health report; sensitivity policy on tool output; `get_index_info`; `pack_context`; the reproducible index hash | 1–2 weeks |
| M5 — Release | Fixture and the four demo repos indexed and published; a README walkthrough with a coding agent using the MCP server; the benchmark page against codebase-memory-mcp and CodeGraphContext; the acceptance checklist | 1 week |

Summaries, model roles, and the cost log return as the first P1 milestone.

## Open decisions

| Decision | Why it matters | Needed by |
| --- | --- | --- |
| Module order after Module 1 | The first recommendation put security and hotspot lenses before docs; the MVP brief names Documentation as the first consumer | End of Module 1 P1 |
| Reuse or build, per lens ([ADR 0001](decisions/0001-compose-dont-rebuild.md), proposed) | Decides which existing tools each lens wraps. The Module 1 index is built in-house ([ADR 0009](decisions/0009-build-the-index-in-house.md)) with imported extraction ([ADR 0011](decisions/0011-scip-first-extraction.md)) | Each lens module's design |
| Which lens comes first after Module 2 | The research shows observability recommendations and findings-to-backlog are the open ground; business docs belong to Module 2 | After Module 2's design |

### Tech stack

- **Decided (2026-09-19):** C#/.NET builds the Module 1 reference implementation ([ADR 0010](decisions/0010-dotnet-reference-implementation.md)). Every contract stays stack-neutral, so TypeScript or Python implementations can follow.
- **Constraint:** Microsoft Agent Framework supports .NET and Python, not TypeScript ([Agent Framework FAQ](https://learn.microsoft.com/agent-framework/support/faq#general), checked 2026-09-19). Module 1 needs no agent framework; the choice matters from the first lens module on.
- **Risks to validate in M1:** the SCIP indexers on the demo repos (how much of each repo resolves), reading SCIP protobuf from .NET, and the syntax pass for C#. Since [ADR 0013](decisions/0013-syntax-pass-on-every-code-file.md), every code file is parsed, so the parser binding risk is back on the primary path. [ADR 0015](decisions/0015-any-parser-that-passes-the-fixtures.md) lets C# use Roslyn's syntax trees instead of tree-sitter, and lets TypeScript and Python use an out-of-process extractor.
- **Still a preference, not a decision:** a React and shadcn/ui frontend, settled with the Platform module.

## GitHub presentation (decided 2026-09-19)

Still to be set on the repository's page:

- **About:** A fact base and lenses for any codebase. Zero-LLM-cost indexing, MCP server for coding agents, BYOK.
- **Topics:** `code-analysis`, `codebase-indexing`, `mcp-server`, `mcp`, `ai-agents`, `code-review`, `documentation-generator`, `static-analysis`, `security-audit`, `developer-tools`, `llm`, `graphrag`, `sqlite`, `dotnet`, `typescript`, `python`
