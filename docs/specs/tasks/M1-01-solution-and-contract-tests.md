# M1-01: Solution, CI, and contract tests

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Stand up the .NET solution, continuous integration, and a test project that validates every M0 contract, so every later task starts from a red or green signal.
- **Depends on:** nothing.
- **Spec references:** [development workflow](../../development-workflow.md); every contract under `docs/specs/`, because the tests read them.
- **Files and interfaces:**
  - `RepoRanger.sln`, `Directory.Build.props` (nullable enabled, warnings as errors, deterministic builds), `.editorconfig`.
  - `src/RepoRanger.Core/` as an empty library, the home of later tasks.
  - `tests/RepoRanger.Contracts.Tests/`: the contract tests below. It reads the files under `docs/specs/` directly, so a contract and its test can never drift.
  - `.github/workflows/ci.yml`: restore, build, test on `ubuntu-latest` and `windows-latest`.
  - `CLAUDE.md`: the build and test commands the workflow expects.
  - `.claude/skills/task/SKILL.md` and `.claude/agents/spec-reviewer.md`, as the workflow plans.
  - Packages: xunit, Microsoft.Data.Sqlite, JsonSchema.Net, Tomlyn. All MIT or Apache-2.0, as [ADR 0007](../../decisions/0007-permissive-licensing.md) requires.
- **Out of scope:** any indexing behaviour; the CLI; anything that reads a repository.
- **Tests first:**
  - `index-schema.sql` loads into an in-memory SQLite database, every table is STRICT, and the ten invalid writes from the schema's own constraints are rejected.
  - Every `mcp-tools/*.json` is an MCP Tool: the name matches the file, the input schema is a closed object with no `$ref`, the output schema requires `_meta`, and its references resolve after bundling.
  - `plugin-facts.json`, `sensitivity-rules.json`, `config.schema.json`, and `golden/golden.schema.json` are valid JSON Schema 2020-12 documents, and their defaults or examples validate.
  - The three conformance facts files validate against `plugin-facts.json`.
  - `golden/*.toml` and the configuration examples parse with Tomlyn and validate.
  - The enums shared between `index-schema.sql`, `mcp-meta.json`, and `plugin-facts.json` are equal.
  - Every relative link in `docs/**/*.md`, anchors included, resolves.
- **Verification step:** `dotnet test` prints all tests passed, with at least one test per contract file, and the CI run on the pull request is green on both operating systems.
- **Done when:** the verification step passes, the tests are committed, the review has no open correctness findings, and `CLAUDE.md` names the build and test commands.
