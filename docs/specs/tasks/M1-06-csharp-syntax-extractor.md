# M1-06: The C# syntax extractor

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Produce the syntax facts for a C# file — declarations, call sites, imports, markers, metrics, and parse errors — matching the committed conformance case exactly.
- **Depends on:** M1-01. It can run beside M1-02 to M1-05.
- **Spec references:** [plugin-interface.md](../plugin-interface.md), sections 3, 4.1, 5, 6, and 10; [plugin-facts.json](../plugin-facts.json); the conformance case [golden/syntax/csharp/basics.cs](../golden/syntax/csharp/basics.cs) and its facts file; [ADR 0013](../../decisions/0013-syntax-pass-on-every-code-file.md) for why the pass runs on every code file, and [ADR 0015](../../decisions/0015-any-parser-that-passes-the-fixtures.md) for the freedom to choose the parser.
- **Files and interfaces:**
  - `src/RepoRanger.Core/Syntax/CSharp/`: `CSharpSyntaxExtractor` over Roslyn syntax trees — parsing only, no compilation, no MSBuild, so a file that does not build still yields facts.
  - It runs in the core's process, which section 1 allows, and returns the same `file_facts` an out-of-process extractor would.
  - Positions are one-based lines with zero-based UTF-8 byte columns; the overload identity string, `has_body`, and `merge` follow section 4.1 so the core's symbol IDs come out right.
- **Out of scope:** resolution of any kind; TypeScript and Python, which arrive in M3; the JSON-RPC transport, which the first out-of-process plugin brings.
- **Tests first:**
  - The conformance case: the extractor's output over `basics.cs` equals `basics.facts.json`, compared as RFC 8785 canonical JSON. This test is the task.
  - Special names (`<ctor>`, `<cctor>`, `<finalizer>`, `this[]`, operators), visibility, modifiers, and doc comments follow section 4.1.
  - Partial types and partial methods carry `merge`, and a partial method's implementation is the one with `has_body`.
  - Metrics match section 5 on hand-counted examples: cyclomatic complexity, nesting depth, lines of code, parameter count.
  - A file with a syntax error yields facts for the rest of it plus an entry in `errors`.
  - Byte columns are right for a file with non-ASCII identifiers and for CRLF text.
  - The same input gives the same output, with no clock, randomness, or network — section 2's determinism rule.
- **Verification step:** `dotnet test --filter CSharpSyntax` passes, including the conformance comparison, and the test prints the declaration, call-site, and import counts — 23, 5, and 2 for the committed case.
- **Done when:** the verification step passes, the tests are committed, and the review has no open correctness findings. If the extractor and the case disagree and the case is wrong, fix the case in its own commit, as the fixture design requires.
