# ADR 0009: Build the Module 1 index in-house

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

The [landscape research](../research/oss-landscape-2026-09.md) first suggested wrapping an existing MIT-licensed code-graph indexer, CodeGraphContext, as the graph and MCP layer. Module 1 then grew from a code graph into a repository fact base: symbols and edges, plus git history and its signals, artifact inventories, provenance on every node and edge, a health report, a sensitivity policy, a reproducible index hash, and one portable SQLite file per repository, all behind stack-neutral contracts.

The candidates reviewed:

- **CodeGraphContext** (MIT): Python; tree-sitter with optional SCIP; MCP server; an embedded graph database rather than SQLite. Wrapping it would tie the engine to Python and leave history, provenance, health, and sensitivity to be built around it.
- **Codebase-Memory-MCP** (MIT): a single native binary with SQLite storage, community detection, and Merkle-diff re-indexing. Fast, but extending it means working inside its codebase, and history and provenance would still be ours to add.

Neither offers the combination Module 1 needs.

## Decision

Module 1 builds its own index engine: the schema, the fact base, history signals, health report, sensitivity policy, and the MCP surface. Existing indexers are references for techniques (Merkle re-indexing, community detection, PageRank-style repo maps) and sources of components. Since 2026-09-19 the parsers are not in-house either: code structure is imported from the SCIP indexers ([ADR 0011](0011-scip-first-extraction.md)).

## Consequences

- More upfront work than wrapping, reduced by importing extraction. The M1 spike validates SCIP coverage, precision, and index size early.
- RepoRanger owns the index format, so the single-file portable index, provenance, and health report are guaranteed rather than bolted on.
- The engine is written in the reference stack ([ADR 0010](0010-dotnet-reference-implementation.md)).
- Revisit if M1 shows extraction performance far behind the wrapped alternatives. The extraction stage could then be delegated to an external tool without changing the contracts.
- This settles the Module 1 part of [ADR 0001](0001-compose-dont-rebuild.md); the reuse-or-build choice for each lens module stays open.
