# ADR 0008: Product name: RepoRanger

- **Status:** Accepted
- **Date:** 2026-09-18 (name); 2026-09-19 (styling and tagline)

## Context

Candidates discussed: Loupe (the discussion's first pick), Quarry, Strata, Cartograph, Sextant, Fathom, Argus, Lodestar, RepoLens, and Codewarden/Repowarden. The owner chose RepoRanger.

Name checks, first on 2026-09-18 and again on 2026-09-19:

- The hyphenated `repo-ranger` is taken on npm (at naming time, an unrelated code-graph navigation CLI) and on PyPI.
- An unrelated project, the "Ranger" GitHub App, uses the `reporanger` GitHub organization and the reporanger.com domain.
- A few other small repositories use "repo-ranger" or "RepoRanger". The bare name `ranger` belongs to a well-known console file manager and to Apache Ranger.
- The unhyphenated `reporanger` was free on npm, PyPI, and NuGet on 2026-09-19.

## Decision

- **RepoRanger** in prose.
- **`reporanger`** (lowercase, no hyphen) for the GitHub repository (`pournasserian/reporanger`), the CLI command, and package names.
- Never `repo-ranger` or a bare `ranger`.
- Tagline: "A fact base and lenses for any codebase."
- GitHub About text: "A fact base and lenses for any codebase. Zero-LLM-cost indexing, MCP server for coding agents, BYOK."

## Consequences

- Reserve `reporanger` on npm, PyPI, and NuGet before a release.
- Search results will mix with the similarly named projects, so the README, the GitHub About text, and the topics must make RepoRanger's scope obvious.
