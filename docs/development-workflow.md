# Development workflow

**Status:** Accepted 2026-09-19 · **Last updated:** 2026-09-19

RepoRanger is built with Claude Code as the primary implementation tool. The workflow layers three approaches, each at the level where it pays off, and keeps every spec as a plain file in this repository. No spec framework.

| Level | Approach | What it means here |
| --- | --- | --- |
| Milestone | Spec-driven | The docs are the spec: the [MVP brief](modules/01-ingest-and-index/mvp-brief.md) is the requirements, the [design notes](modules/01-ingest-and-index/design-notes.md) and [decision records](decisions/README.md) are the design, the [roadmap](roadmap.md) is the plan. Each milestone item gets a one-page task spec before any code. |
| Interface | Contract-first | The M0 contracts (SQLite DDL, JSON Schemas for the MCP tools and `_meta`, the plugin interface, the golden-sample format) are files that tests validate. They keep the contracts stack-neutral by construction. |
| Task | Test-driven | Tests are written and committed before the implementation, and the implementation is done when they pass. The in-repo fixture with known counts is the accuracy oracle. |
| Done | Adversarial review | A reviewer in a fresh context checks the diff against the task spec and reports gaps in correctness and scope only. The session that wrote the code does not grade it. |

## Why this shape

Claude Code stops when the work looks done, so every task needs a check it can run itself: a test suite, a schema validation, a fixture comparison. Specs live in files because they survive context compaction and session resets; the conversation does not. Contracts as files make stack neutrality something CI enforces rather than something people remember.

## Specs in the repository

| Location | Holds | When |
| --- | --- | --- |
| `docs/` | Requirements, design, decisions, plan | Now |
| `docs/specs/` | The contracts: `index-schema.sql`, `mcp-tools/<tool>.json` and `mcp-meta.json` (JSON Schema for requests and responses), `mcp-usage.md` (server instructions and usage prompt), `plugin-interface.md` and `plugin-facts.json` (JSON Schema for plugin messages and facts), `sensitivity-rules.md` and `sensitivity-rules.json` (rule model and default rules), `config.md` and `config.schema.json` (configuration and registry), `fixture/README.md` (fixture design), `golden/golden.schema.json`, `golden/<language>.toml` ([ADR 0017](decisions/0017-toml-for-configuration-and-golden-files.md)), and the syntax conformance cases under `golden/syntax/` | M0 |
| `docs/specs/tasks/<milestone>-<nn>-<slug>.md` | One page per task, using the template below | From M0, for M1 onward |

### Task spec template

```markdown
# M1-02: SCIP importer for C#

- **Goal:** one sentence.
- **Spec references:** the contract files and brief sections this task implements.
- **Files and interfaces:** what is created or changed; the public surface it exposes.
- **Out of scope:** what this task deliberately does not do.
- **Tests first:** the tests to write before implementing (contract, fixture, unit).
- **Verification step:** the command that proves the task works, and what its output must show.
- **Done when:** the verification step passes, tests are committed, review has no open correctness findings.
```

A task spec is self-contained: someone with only that page and the contracts can do the work.

## The task loop

1. **Start clean.** New session, plan mode. Read the task spec and the contracts it references. Nothing else.
2. **Plan.** List the files to change and the tests to write. Approve or edit the plan before leaving plan mode. Skip planning only when the change fits in one sentence.
3. **Tests first.** Write the failing tests (contract tests from the schemas, fixture-based tests, unit tests; no mocks of the store). Run them, confirm they fail for the right reason, commit them.
4. **Implement** until the tests pass, without modifying the tests. If a test is wrong, say so and fix it in a separate, explained commit; if the spec is wrong, fix the spec first.
5. **Verify.** Run the task's verification step and show the evidence: the command and its output, not a claim.
6. **Review.** `/code-review` for bugs; the spec-reviewer subagent for gaps against the task spec. Address findings that affect correctness or the stated requirements; treat the rest as optional.
7. **Pull request.** The description cites the task spec and includes the evidence. CI must be green.
8. **Reset.** `/clear` before the next task.

## Definition of done

A task is done when its verification step passes, its tests are committed, the contract and schema tests pass, the review has no open correctness findings, and any divergence from the spec has been written back into the spec or a decision record.

## Tooling that arrives with M1

- `CLAUDE.md` gains the build and test commands.
- `.claude/skills/task/SKILL.md`: the task loop above as a manually invoked workflow.
- `.claude/agents/spec-reviewer.md`: a read-only reviewer with the task spec and the acceptance criteria as its only inputs.
- Hooks: format on every edit; a Stop hook that runs the affected test project, so a turn cannot end red.
- CI (GitHub Actions): build, tests, schema validation, the golden-sample precision gate, and the docs link check.
- Later: `/goal` for unattended runs, and git worktrees when two tasks run in parallel, such as M3's two importers.

## Session hygiene

- One task per session. Long sessions with unrelated context degrade results.
- Use subagents for exploration so file reads stay out of the main context.
- After two failed corrections on the same issue, restart with a better prompt instead of a third correction.
- Keep `CLAUDE.md` short. Domain knowledge and workflows go in skills, which load on demand.

## Anti-patterns

- Implementation first, tests after. Claude does this by default; the task loop exists to prevent it.
- Editing a test to make it pass.
- Fixing every reviewer finding. A reviewer asked for gaps will always find some.
- Code that diverges from the spec without the spec changing.

## What was not chosen

- **Spec Kit and OpenSpec:** both work with Claude Code, but their constitution → spec → plan → tasks pipeline duplicates what `docs/` already is. Revisit if contributors need the ceremony.
- **BDD with Gherkin:** the brief's acceptance criteria are already testable statements; automate them directly.
