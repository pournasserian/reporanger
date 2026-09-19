# Task specs

**Status:** Proposed · **Last updated:** 2026-09-19

One page per task, in the template from the [development workflow](../../development-workflow.md#task-spec-template). A task spec is self-contained: someone with only that page and the contracts it names can do the work. Each page adds a **Depends on** line, because the M1 tasks build on each other.

Run one task per session, following the [task loop](../../development-workflow.md#the-task-loop): plan, tests first, implement, verify, review, pull request, reset.

## M1 — SCIP spike

The milestone's goal is the [roadmap](../../roadmap.md#module-1-milestones-proposed)'s: discovery, the syntax pass and the SCIP importer for C#, the SQLite writer, and `repo_map`, `find_symbols`, and `get_symbol` over the CLI, measured on dotnet/orleans.

| Task | Does | Depends on |
| --- | --- | --- |
| [M1-01](M1-01-solution-and-contract-tests.md) | Solution, CI, and tests that validate every M0 contract | – |
| [M1-02](M1-02-configuration.md) | Configuration and the registry | M1-01 |
| [M1-03](M1-03-discovery.md) | Discovery, content hashes, and C# project detection | M1-02 |
| [M1-04](M1-04-sensitivity-engine.md) | The sensitivity rules: matching, redaction, response pass | M1-01 |
| [M1-05](M1-05-sqlite-writer.md) | The index file: writing, batching, and the index hash | M1-03, M1-04 |
| [M1-06](M1-06-csharp-syntax-extractor.md) | The C# syntax extractor | M1-01 |
| [M1-07](M1-07-scip-dotnet-runner.md) | Running scip-dotnet from a descriptor | M1-03 |
| [M1-08](M1-08-scip-importer.md) | Turning SCIP output into nodes and edges | M1-05, M1-06, M1-07 |
| [M1-09](M1-09-fixture-csharp.md) | The C# fixture and its expectations | M1-08 |
| [M1-10](M1-10-query-and-cli.md) | The query set and the CLI | M1-08 |
| [M1-11](M1-11-orleans-measurement.md) | Indexing dotnet/orleans, and the M1 report | M1-09, M1-10 |

Two tasks can run in parallel where nothing connects them, such as M1-04 and M1-06 while M1-03 is in progress. The [development workflow](../../development-workflow.md#tooling-that-arrives-with-m1) mentions git worktrees for that.

## Later milestones

M2 to M5 get their task specs when their milestone starts, from the same template. The roadmap holds their scope.
