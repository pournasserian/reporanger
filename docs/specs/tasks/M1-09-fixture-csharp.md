# M1-09: The C# fixture and its expectations

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Build the C# half of the fixture repository and fill its expectations by hand, so accuracy becomes a number CI can check rather than an impression.
- **Depends on:** M1-08.
- **Spec references:** [fixture/README.md](../fixture/README.md), sections 2, 3, 4, 6, 7, and 8; [golden/csharp.toml](../golden/csharp.toml) and [golden/golden.schema.json](../golden/golden.schema.json).
- **Files and interfaces:**
  - `fixture/csharp/`: `Fixture.sln`, `src/Shop/` (the library the golden edges cover, exercising overloads, a generic method, a conversion operator, an indexer, a partial type across two files, records, enums, delegates, events, and an explicit interface implementation), `tests/Shop.Tests/` (xUnit, naming and calling the code under test), `broken/Broken.csproj` (a package reference that cannot restore).
  - `fixture/.reporanger.toml`, the planted `{{secret:<rule id>}}` placeholders of section 6 beside literal near misses, and `.gitattributes` marking the fixture so this repository never indexes it.
  - `docs/specs/golden/csharp.toml`: the `[fixture]` `edges` and `absent` lists, every one written by hand.
  - `fixture/expected/csharp-counts.toml`: files by extraction status, symbols by kind, edges by type and resolution, diagnostics by code.
- **Out of scope:** TypeScript and Python, which M3 brings; `fixture/history.toml`, which M3 fills with the history signals; the `[demo]` section of `csharp.toml`, which is M1-11.
- **Tests first:**
  - Indexing a copy of the fixture reproduces `expected/csharp-counts.toml` exactly.
  - Precision and recall against `golden/csharp.toml` are at or above its thresholds, and every edge listed under `absent` is missing.
  - `broken/` is recorded as `fallback` with an `indexer_failed` diagnostic, and its files carry no CALLS edges.
  - The test project's tests map to the code they exercise once test-to-code mapping exists; until then the test asserts the marker facts the syntax pass produced.
  - A copy with generated secrets written into the placeholders, indexed, exposes no planted secret in any response, and the literal near misses survive.
  - Indexing the fixture twice gives the same index hash.
- **Verification step:** `dotnet test --filter Fixture` passes and prints the precision and recall figures with the counts they came from.
- **Done when:** the verification step passes, the expectation files are committed with the fixture in the same commit, and the review has no open correctness findings.
