# RepoRanger

Design phase: this repository holds documentation only. No code until the Module 1 contracts exist under `docs/specs/` (milestone M0).

## Where things are

- `docs/README.md` is the index. Read `docs/modules/01-ingest-and-index/mvp-brief.md` before touching anything in Module 1.
- Decisions live in `docs/decisions/`. Never edit an accepted decision; add a new record that supersedes it.
- The way code will be written is in `docs/development-workflow.md`.

## Conventions

- Product name: RepoRanger in prose; `reporanger` for the repository, CLI, and packages. Never `repo-ranger`.
- Every document starts with a status line (Draft, Proposed, or Accepted) and a last-updated date in YYYY-MM-DD.
- Contracts (index schema, MCP tool shapes, plugin interface, config formats) stay stack-neutral. The reference implementation is C#/.NET.
- Use the terms in `docs/glossary.md`; add new ones there.
- Links between documents are relative and must resolve; check them before committing.

## Rules

- Change the spec or the decision record before diverging from it.
- Present decisions as questions with a recommended option, and wait for approval before changing accepted documents.
- Do not propose implementation detail or a stack for anything that has no approved spec yet.

## Build and test

Added at M1.
