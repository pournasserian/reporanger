# Architecture decision records

**Last updated:** 2026-09-19

Each record captures one significant decision: its context, the decision, and its consequences. Records are never deleted; a changed decision gets a new record that supersedes the old one.

| ADR | Decision | Status | Date |
| --- | --- | --- | --- |
| [0001](0001-compose-dont-rebuild.md) | Compose existing tools; build the fact base and the differentiators | Proposed | 2026-09-18 |
| [0002](0002-byok-and-model-roles.md) | Bring your own key, with model roles | Accepted | 2026-09-18 |
| [0003](0003-retrieval-graph-fts-graphrag-lite.md) | Graph and full-text retrieval required; semantic search deferred; GraphRAG-lite | Accepted | 2026-09-18 |
| [0004](0004-storage-abstraction-by-capability.md) | Storage abstraction by capability, not by vendor | Accepted | 2026-09-18 |
| [0005](0005-sqlite-for-mvp.md) | SQLite for the MVP | Accepted | 2026-09-18 |
| [0006](0006-markdown-for-humans-db-as-cache.md) | Markdown for human-facing docs; the index is a rebuildable cache | Accepted in principle | 2026-09-18 |
| [0007](0007-permissive-licensing.md) | MIT license; copyleft only out of process | Accepted | 2026-09-18 |
| [0008](0008-product-name.md) | Product name: RepoRanger | Accepted | 2026-09-18 |
| [0009](0009-build-the-index-in-house.md) | Build the Module 1 index in-house | Accepted | 2026-09-19 |
| [0010](0010-dotnet-reference-implementation.md) | C#/.NET builds the Module 1 reference implementation | Accepted | 2026-09-19 |
| [0011](0011-scip-first-extraction.md) | Import code structure from SCIP indexes; tree-sitter only as a fallback | Accepted | 2026-09-19 |

Module-level decisions live with their module, e.g., the [Module 1 MVP decisions](../modules/01-ingest-and-index/mvp-brief.md#decisions-confirmed-2026-09-19). Pending decisions (tech stack, demo repositories, module order) are tracked in the [roadmap](../roadmap.md#open-decisions).

## Adding a record

Copy the template into `NNNN-short-title.md` with the next number, set the status to `Proposed`, and open a pull request.

```markdown
# ADR NNNN: Title

- **Status:** Proposed | Accepted | Superseded by ADR NNNN
- **Date:** YYYY-MM-DD

## Context

What forces are at play, and why a decision is needed now.

## Decision

What we decided, stated plainly.

## Consequences

What becomes easier, harder, or required as a result.
```
