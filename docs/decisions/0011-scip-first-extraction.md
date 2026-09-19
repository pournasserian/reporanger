# ADR 0011: Import code structure from SCIP indexes; tree-sitter only as a fallback

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

The MVP planned to write tree-sitter extractors for C#, TypeScript/JavaScript, and Python in P0 and language-native deep analyzers (Roslyn first) in P1. The review of 2026-09-19 against the current field ([research](../research/oss-landscape-2026-09.md)) changed the picture:

- Code-graph indexing is the most crowded category in the landscape, with at least six actively maintained tools and two above 40k stars. Language count is not a differentiator RepoRanger can win.
- Accuracy is. In a compiler-graded benchmark of 37,853 call edges, tree-sitter-based tools show recall between 0.03 and 0.97 depending on the repository, and a hand-graded sample puts one leading tool at 58.6% precision across nine languages. The tool that wins those benchmarks stamps every edge with how it was resolved.
- Sourcegraph maintains SCIP indexers for exactly the MVP languages: scip-dotnet (Roslyn-based), scip-typescript, and scip-python, all Apache-2.0. They emit compiler-resolved definitions, references, and relationships in one protobuf format. CodeGraphContext already uses scip-dotnet for C# precision.

## Decision

- **Primary extraction in P0 is a SCIP importer.** RepoRanger runs the SCIP indexer for each project it discovers (or ingests a pre-built `index.scip`) and maps documents, symbols, occurrences, and relationships onto its own nodes and edges. Every edge from this path has resolution level `resolved`.
- **Fallback in P0 is tree-sitter for symbols and imports only**, for projects that don't build. Its edges are `import-scoped` or `name-match`, and the health report lists every project on the fallback.
- **Full tree-sitter call extraction is P1, and only if a language without a SCIP indexer needs it.**
- **Language-native analyzers move to P2**, and only for facts SCIP doesn't carry. Framework-level facts (DI registrations, endpoints, ORM entities, middleware) come from the P1 inventories.

This refines [ADR 0009](0009-build-the-index-in-house.md): RepoRanger still owns the schema and the fact base, but not the parsers.

## Consequences

- One importer replaces three extractors and three deep analyzers; the milestone plan drops from 9–11 to 7–9 weeks.
- The demo repositories must build for their indexer (a restore for C#, a `tsconfig` for TypeScript, a resolvable environment for Python). The in-repo fixture includes a project that deliberately doesn't build, to test the fallback.
- RepoRanger depends on Sourcegraph maintaining the indexers. The dependency is external-process only, and the importer interface is the same plugin interface a community extractor would use, so a replacement indexer is a plugin, not a rewrite.
- String literals and annotations are not in SCIP output, so the flagging that feeds the P1 inventories needs a tree-sitter pass in P1.
- Extraction precision becomes an acceptance criterion (at least 90% on the golden sample) and a CI check, because the whole point of this decision is to be measurably more precise than heuristic graphs.
