# M1-08: The SCIP importer

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Read a SCIP index, attach its symbols to the declarations the syntax pass found, and write nodes and edges with a resolution level and provenance on every one.
- **Depends on:** M1-05, M1-06, M1-07.
- **Before it starts:** the SCIP format is protocol buffers, and `Google.Protobuf` is BSD-3-Clause, which [ADR 0007](../../decisions/0007-permissive-licensing.md) does not name — it allows MIT and Apache-2.0 in process. Record a decision that widens the allowed set, or read the two message types by hand, before taking a dependency.
- **Spec references:** [plugin-interface.md](../plugin-interface.md), sections 7.2 to 7.4 and 8; [index-schema.sql](../index-schema.sql), sections 3 and 7, for symbol IDs, `nodes`, and `edges`; [ADR 0012](../../decisions/0012-resolution-levels-for-every-edge.md) for the resolution levels, [ADR 0014](../../decisions/0014-symbol-id-scheme.md) for the IDs.
- **Files and interfaces:**
  - `src/RepoRanger.Core/Scip/`: `ScipReader`, `SymbolParser` (the symbol grammar and its descriptors), `Attacher` (a SCIP symbol joins a syntax declaration by name and position, because scip-dotnet reports no kind, signature, or enclosing range), `EdgeBuilder` (occurrences become CALLS, REFERENCES, and IMPORTS; relationships become INHERITS and IMPLEMENTS), `ExternalNodes` (`ext:` nodes for symbols outside the repository).
  - Everything the importer writes is `resolved`. The `import-scoped` and `name-match` levels come from the fallback of section 8, which this task also implements for files no SCIP index covers.
- **Out of scope:** the other languages' indexes; CO_CHANGES, TESTS, and DEPENDS_ON edges, which arrive with history and manifests in M3.
- **Tests first:**
  - A recorded `index.scip` from a small project, committed as a test resource, produces exactly the expected nodes and edges.
  - A SCIP symbol whose name and position match a declaration attaches to it; one that matches nothing raises `unmatched_definitions` and is counted, not dropped silently.
  - Overloads: the order-based `(+N)` suffix maps onto the declaration the syntax pass found at that position, and the resulting symbol IDs are the scheme's, not SCIP's.
  - An external symbol becomes one `ext:` node, shared by every caller, with no span and no content hash.
  - A project that fell back yields IMPORTS and name-match edges only, never a `resolved` one.
  - Every edge carries its extractor, its file, its line, and a resolution level; the schema's check on CONTAINS, DEPENDS_ON, and CO_CHANGES still holds.
  - Re-importing the same SCIP file twice leaves the index and its hash unchanged.
- **Verification step:** indexing the fixture's building C# project prints counts by node kind, edge type, and resolution level, and a test asserts them; `dotnet test --filter Scip` passes.
- **Done when:** the verification step passes, the tests are committed, the licence question above is decided in the repository, and the review has no open correctness findings.
