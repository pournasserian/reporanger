# ADR 0015: Any parser that passes the fixtures may implement a language's syntax pass

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

[ADR 0011](0011-scip-first-extraction.md) made the fallback "tree-sitter for symbols and imports". [ADR 0013](0013-syntax-pass-on-every-code-file.md) then put a syntax pass on every code file and made it the source of symbol IDs in both modes. It chose no parser for projects that build, but because both modes must produce the same IDs, ADR 0011's wording in practice pins tree-sitter for every file. ADR 0013 also noted that this puts the .NET tree-sitter binding risk back on the primary path.

The [plugin interface](../specs/plugin-interface.md) defines the syntax pass as facts: declarations, call sites, imports, markers, and metrics, following rules per language. Golden fixtures (M0 item 5) check those facts. A contract defined by its output doesn't need to name a parser.

## Decision

- A language's syntax pass is correct when its facts match the golden fixtures for that language. Any parser that passes may implement it.
- One implementation uses one syntax extractor per language, in both modes, so fallback and SCIP IDs still agree (ADR 0013).
- Tree-sitter stays the default parser and the one ADR 0011 names for the fallback. Where a language's extractor uses another parser, that parser also serves that language's fallback.

## Consequences

- This amends ADR 0011's "tree-sitter for symbols and imports": for the fallback, read "the language's syntax extractor, tree-sitter by default".
- The .NET implementation may use Roslyn's syntax trees for C# in both modes, which retires the .NET tree-sitter binding risk for C#. TypeScript and Python can use tree-sitter in-process, or through an out-of-process extractor that uses tree-sitter's official bindings.
- Two implementations can use different parsers for the same language. The fixtures keep their facts equal on everything the fixtures cover; they may differ on code the fixtures don't cover.
- The golden fixtures carry more weight: they are the only definition of correct extraction, so M0 item 5 must cover every rule in the plugin interface.
