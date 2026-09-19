# ADR 0010: C#/.NET builds the Module 1 reference implementation

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

The implementation stack was undecided. The stated preference was backends in C#, TypeScript, and Python, possibly all three, using Microsoft Agent Framework, with a React and shadcn/ui frontend. Microsoft Agent Framework supports .NET and Python but not TypeScript ([Agent Framework FAQ](https://learn.microsoft.com/agent-framework/support/faq#general), checked 2026-09-19).

Module 1 needs no agent framework: it is deterministic except for lazy summaries, so it needs a parser, SQLite, git access, a model client, and an MCP SDK.

| Need | C#/.NET | TypeScript/Node | Python |
| --- | --- | --- | --- |
| tree-sitter bindings | Community bindings; no official one from the tree-sitter project | Official | Official |
| SQLite | First-class | First-class | First-class |
| Git access | LibGit2Sharp | simple-git, nodegit | GitPython, pygit2 |
| MCP SDK | Official | Official | Official |
| Model client | Microsoft.Extensions.AI | OpenAI SDK, Vercel AI SDK | OpenAI SDK, LiteLLM |
| Distribution | `dotnet tool install` | `npx` | `pipx`, `uv` |
| First deep analyzer | Roslyn, native to the stack | TypeScript compiler API | LibCST, Jedi |
| Microsoft Agent Framework (lens modules, later) | Yes | No | Yes |

## Decision

C#/.NET builds the first index engine. Every contract stays stack-neutral: the index schema (SQLite DDL), the MCP tool request and response shapes, the extractor plugin interface, and the model-role configuration format. TypeScript or Python implementations can follow if wanted.

## Consequences

- The CLI ships as a `dotnet tool`; Roslyn is the natural first deep analyzer in P1.
- Since [ADR 0011](0011-scip-first-extraction.md), primary extraction is a SCIP importer (protobuf, read with Google.Protobuf), so the .NET tree-sitter binding risk only affects the fallback path. M1 validates the importer and SCIP coverage instead.
- Microsoft Agent Framework is available when lens modules need orchestration. A TypeScript backend would need a different agent layer.
- The frontend preference (React and shadcn/ui) is decided with the Platform module, not here.
