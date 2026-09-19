# ADR 0007: MIT license; copyleft only out of process

- **Status:** Accepted
- **Date:** 2026-09-18

## Context

RepoRanger is a personal open-source project, and adoption and reuse matter more than control. Several useful tools in the landscape are copyleft (AGPL, GPL, CC-BY-SA), and a few licenses were uncertain during the research.

## Decision

- RepoRanger is licensed under the [MIT License](../../LICENSE).
- In-process dependencies must be permissively licensed (MIT or Apache-2.0).
- Copyleft tools run only as optional external processes or sidecars, or serve as design references. Examples: Qodo Cover (AGPL-3.0) and Kodus (reported as AGPL-3.0).
- Weak-copyleft tools such as Semgrep CE (LGPL-2.1) are invoked as external tools, not linked.
- Copyleft prompt content, such as Trail of Bits' skills (reported as CC-BY-SA-4.0), stays isolated.
- Every dependency's license is checked in its own repository before adoption.

## Consequences

- A dependency license check belongs in CI once code exists.
- Some good tools can only be used as separate services, which costs integration work.
- Licenses and ownership change: the research reported Codebase-Memory-MCP as GPL-3.0, but GitHub showed MIT on 2026-09-19.
