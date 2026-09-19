# M1-10: The query set and the CLI

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Answer `repo_map`, `find_symbols`, and `get_symbol` from an index file, in the shapes the MCP contracts state, and expose them plus `index_repo` over a command line.
- **Depends on:** M1-08.
- **Spec references:** [mcp-meta.json](../mcp-meta.json) for the conventions, the limits, the error codes, and the shared definitions; [repo_map.json](../mcp-tools/repo_map.json), [find_symbols.json](../mcp-tools/find_symbols.json), [get_symbol.json](../mcp-tools/get_symbol.json), and [index_repo.json](../mcp-tools/index_repo.json); [sensitivity-rules.md](../sensitivity-rules.md), section 5, for the response pass.
- **Files and interfaces:**
  - `src/RepoRanger.Core/Query/`: one handler per tool, each taking the tool's input object and returning its output object, with `_meta` on every response — index hash, freshness, sensitivity, and truncation.
  - Shared: `Paging` (a stable order and an opaque cursor), `IncludeFlags`, `ResponseBudget` (the token budget of `mcp-meta.json`, truncating with a flag rather than silently), `Targets` (many targets, and the limit on how many).
  - `src/RepoRanger.Cli/`: `reporanger index`, `map`, `find`, `symbol`, printing the same objects as JSON, so the CLI and the MCP server of M4 cannot drift.
- **Out of scope:** the MCP server, its resources, and the usage prompt, which are M4; the other ten tools, which are M2 and M3.
- **Tests first:**
  - Every response validates against its tool's `outputSchema`, and every example in the tool files round-trips.
  - `_meta` reports the index hash and a freshness that turns stale when a file changes under the index.
  - Paging is stable: the pages of a query concatenate to the unpaged result, with no repeats and no gaps, and a cursor survives a re-run.
  - More targets than the limit, an unknown symbol ID, and a missing index each produce the documented error code, with `isError` set.
  - A response past the budget is truncated and says so; nothing is dropped without the flag.
  - The response pass of M1-04 runs on every response: a withheld file appears with no content, and a redacted value is redacted in every field it reaches.
  - `include` flags add exactly their documented fields and nothing else.
- **Verification step:** `dotnet run --project src/RepoRanger.Cli -- map --index <fixture index>` and `... symbol <an ID from the fixture>` print valid responses, and a test validates both against the tool schemas; `dotnet test --filter Query` passes.
- **Done when:** the verification step passes, the tests are committed, and the review has no open correctness findings.
