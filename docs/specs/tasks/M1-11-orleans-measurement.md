# M1-11: Indexing dotnet/orleans, and the M1 report

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Index a real repository end to end, measure what it cost and how accurate it was, and write down what the numbers mean for the rest of Module 1.
- **Depends on:** M1-09, M1-10.
- **Spec references:** the [MVP brief](../../modules/01-ingest-and-index/mvp-brief.md), its scope and acceptance criteria; the [roadmap](../../roadmap.md)'s M1 row; the `[demo]` section of [golden/csharp.toml](../golden/csharp.toml); [fixture/README.md](../fixture/README.md), section 7.
- **Files and interfaces:**
  - `docs/reports/m1-scip-spike.md`: the measurements, what surprised us, and what it changes.
  - `docs/specs/golden/csharp.toml`: `[demo]` filled — the pinned `commit`, and the 30 sampled call edges judged by hand at the recorded `sample_seed`.
  - `src/RepoRanger.Cli/`: a `measure` verb, or a script beside it, that prints the figures the report quotes.
- **Out of scope:** the other three demo repositories, which belong to M3 and M5; tuning for speed beyond what the measurement shows is needed.
- **Tests first:**
  - The sampler is deterministic: the same seed and size pick the same 30 edges from the same index.
  - Precision counts an edge correct only when the recorded hand judgement says so, and an unjudged edge fails the run rather than passing quietly.
  - Indexing the same commit twice gives the same index hash, on a second machine or a second operating system if one is available.
  - `get_symbol` and `find_symbols` answer within the response budget on the largest file in the repository.
- **Verification step:** index `dotnet/orleans` at the pinned commit and print wall time, peak memory, index size, node and edge counts, the extraction status of every project, the diagnostics by code, and the precision on the 30 sampled edges. The output goes into the report verbatim.
- **Done when:** the report is committed with the filled sample, precision is at or above the sample's threshold or a decision record explains the gap and what changes, and the roadmap's M1 row is ticked with the measured figures.
