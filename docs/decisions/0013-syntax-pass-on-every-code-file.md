# ADR 0013: A syntax pass runs on every code file

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

[ADR 0011](0011-scip-first-extraction.md) made SCIP the primary source of code structure, with tree-sitter as a fallback for projects that don't build. [ADR 0010](0010-dotnet-reference-implementation.md) concluded that the .NET tree-sitter binding risk therefore only affects the fallback path.

Designing the [index schema](../specs/index-schema.sql) showed two gaps:

- P0 needs facts that SCIP doesn't carry at all: cyclomatic complexity, nesting depth, LOC, and parameter count per symbol.
- The indexers leave out facts the schema needs. Checked against their sources on 2026-09-19:
  - scip-dotnet 0.2.14 sets no symbol kind, signature, or definition span, and keeps only the innermost namespace segment in its symbols. It numbers overloads by counting earlier members with the same name, so inserting an overload renumbers the ones after it.
  - scip-typescript 0.4.0 and scip-python 0.6.6 have no overload marker, and give definition spans for only some declarations.
  - SCIP occurrences carry no call role, so calls can't be told apart from other references.

## Decision

- Every code file gets a syntax pass, whether or not its project builds.
- The syntax pass supplies each declaration's span, fine kind, qualified name, parameter list, doc comment, and metrics, and it identifies call sites.
- SCIP supplies resolution: which symbol each occurrence refers to, and the relationships between symbols. The SCIP importer attaches SCIP symbols to the syntax pass's declarations by definition location.
- Symbol IDs are defined on source text and computed from the syntax pass in both modes ([ADR 0014](0014-symbol-id-scheme.md)).
- For projects that don't build, the syntax pass is the only source: this is ADR 0011's tree-sitter fallback. This record doesn't choose the parser for the other projects. The plugin interface spec (M0) defines the syntax pass contract.

## Consequences

- A parser is on the primary path for all three languages, not only on the fallback path. This amends ADR 0010's consequence that the .NET tree-sitter binding risk only affects the fallback path. M1 includes the syntax pass for C# and measures its cost.
- Fallback and SCIP produce the same symbol IDs, so a project that starts building keeps its IDs.
- CALLS edges depend on the syntax pass to tell a call from any other reference.
- Indexing time includes a parse of every code file. M1 and M3 measure it.
