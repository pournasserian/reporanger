# ADR 0012: Every edge carries a resolution level, structural edges included

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

The [MVP brief](../modules/01-ingest-and-index/mvp-brief.md#p0-feature-list) requires every edge to carry a type, a weight, provenance, and a resolution level: `resolved`, `import-scoped`, or `name-match`. [ADR 0011](0011-scip-first-extraction.md) and the [glossary](../glossary.md) describe `resolved` as resolved by a compiler, and say the fallback's edges are `import-scoped` or `name-match`.

That wording fits reference edges: imports, calls, references, and inheritance. The index also has edges that need no name lookup at all (containment, dependencies read from manifests and lockfiles, change coupling from git history) and test-to-code edges found by heuristics. The [index schema](../specs/index-schema.sql) needs a rule for them. A NULL level would break "every edge", and `resolved` read as "by a compiler" would claim something that never happened.

## Decision

- The resolution level records how an edge's target was identified. The weight records how strong the link is.
- `resolved` means the target was identified exactly: by a compiler (SCIP) for reference edges, or by a structural fact that needs no name lookup. CONTAINS, DEPENDS_ON, and CO_CHANGES edges are `resolved` whichever extractor produced them, including containment found by the fallback.
- Reference edges from the fallback are never `resolved`. They are `import-scoped` or `name-match`, as ADR 0011 says. In P0 the fallback's only reference edges are imports.
- TESTS edges take the level of their evidence: a resolved call from the test to the target gives `resolved`, the test importing the target's file gives `import-scoped`, and a naming convention alone gives `name-match`. When several heuristics agree, the edge records the strongest level and its weight counts the heuristics.

## Consequences

- Every edge has a level, as the brief requires. There are no NULLs and no fourth level.
- ADR 0011's statement about fallback edges applies to reference edges. This record clarifies ADR 0011 and supersedes nothing.
- The glossary's definition of resolution level is reworded to match.
- A consumer that wants only compiler-resolved code relationships filters on the edge type as well as the level.
