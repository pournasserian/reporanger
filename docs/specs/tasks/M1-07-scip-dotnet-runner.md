# M1-07: Running scip-dotnet

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Run `scip-dotnet` over the C# projects a repository holds, from the indexer descriptor, and turn every way it can fail into a recorded fallback rather than a stopped index.
- **Depends on:** M1-03.
- **Spec references:** [plugin-interface.md](../plugin-interface.md), sections 7.1 and 7.2; the `indexer_descriptor` definition in [plugin-facts.json](../plugin-facts.json); [config.md](../config.md), section 4, for the indexer settings and timeouts; [index-schema.sql](../index-schema.sql) for the `extractors` and `diagnostics` tables; [ADR 0011](../../decisions/0011-scip-first-extraction.md).
- **Files and interfaces:**
  - `src/RepoRanger.Core/Indexers/`: `DescriptorLoader` (validates a descriptor against the schema), `IndexerRunner` (working directory, arguments, environment, timeout, kills the whole process tree), `ToolProbe` (records the tool name and version in `extractors`, which is where a SCIP indexer's provenance comes from), `FallbackDecision` (a project that cannot restore or build becomes `fallback`, with an `indexer_failed` diagnostic).
  - The descriptor for scip-dotnet ships with the reference implementation and is data, not code.
- **Out of scope:** reading the SCIP file, which is M1-08; any other language's indexer.
- **Tests first:**
  - The shipped descriptor validates, and a descriptor with an unknown key or a missing command is refused.
  - A stub executable stands in for the indexer: it records its arguments, writes a canned `index.scip`, and can exit zero, exit non-zero, hang, or write nothing. Each case produces the right outcome, and the hang is killed at the timeout.
  - A missing tool produces a diagnostic naming the tool, not an exception.
  - The tool's name and version reach `extractors`, and every node the import later writes can point at that row.
  - Standard error is captured as logs and never parsed.
  - Projects are indexed in a deterministic order, and one project's failure does not affect another's.
- **Verification step:** `dotnet run --project src/RepoRanger.Cli -- index --only-scip <a small C# project>` prints the command line, the exit code, the elapsed time, and the size of the produced `index.scip`; when `scip-dotnet` is not installed, the same command prints the diagnostic and carries on, and the tests cover both through the stub.
- **Done when:** the verification step passes, the tests are committed, and the review has no open correctness findings.
