# Vision

**Status:** Draft · **Last updated:** 2026-09-19

RepoRanger turns any codebase into a queryable fact base, then runs lenses over it to produce the documents and plans a team needs: developer, business, and LLM-friendly docs; audits; bug and enhancement reports; test and observability plans; and an implementation backlog.

## The problem

Teams with many repositories need the same things from each one: documentation for developers and for the business, context for coding agents, audits, bug reports, improvement plans, and a backlog to act on. Doing that by hand doesn't scale.

Pointing an LLM at a whole repository doesn't scale either. Large repositories overflow context windows, runs get slow and expensive, and the answers come back without evidence.

## What RepoRanger will produce

These ten capabilities started the project:

1. **Developer documentation:** architecture, modules, APIs, and diagrams.
2. **Business documentation:** what the system does, written for non-developers.
3. **LLM-friendly documentation:** context files and packs for coding agents.
4. **Audit reports:** security, performance, and quality.
5. **Bug reports:** bugs, performance problems, security issues, and bottlenecks, with evidence.
6. **Enhancement documents:** performance, logging, coding guidelines for the tech stack, and best practices.
7. **Improvement suggestions:** major and minor.
8. **Test review:** coverage gaps and test cases to add or improve, and a plan to start testing where no tests exist.
9. **Logging and observability review:** how to improve observability, traceability, maintainability, performance, and security, including KPIs, indicators, alerts, and dashboards. This is a recommendations document, not an implementation.
10. **Implementation backlog:** the work items that come out of everything above.

The capabilities are organized into eight [feature groups](feature-groups.md).

## How it works

RepoRanger has three layers with a strict contract between them.

1. **Fact base (index).** Deterministic, cheap, and incremental: the code graph, git history, repository artifacts, and metrics, with provenance on everything. It costs no LLM tokens apart from lazy, cached summaries.
2. **Lenses.** One analysis pass per capability, run over the same fact base within a token budget. Lenses emit structured, evidence-backed findings, not prose.
3. **Renderers.** Documents, llms.txt and AGENTS.md files, and backlog items are views over findings and summaries, so one analysis run can feed many outputs.

The same queries are available through a CLI, an MCP server for coding agents, and later a web UI.

## Principles

- **Index once, at zero LLM cost.** Parsing, graphs, history, and metrics are deterministic. LLM spend is limited to lazy, cached summaries and lens work, and it is metered.
- **Evidence first.** Every node, edge, and finding carries provenance: file, line range, and commit.
- **Scale by structure, not by context size.** Community detection, hierarchical summaries, and token-budgeted context packs replace whole-repo dumps. The target is repositories of about 1M LOC and 20k files, on a laptop.
- **Bring your own key.** Users choose providers and models per role, with no vendor or runtime lock-in ([ADR 0002](decisions/0002-byok-and-model-roles.md)).
- **Local-first and portable.** Each repository gets one index file that can be copied, shared, and rebuilt.
- **Stack-neutral contracts.** Schemas, tool surfaces, and plugin interfaces don't assume an implementation language.
- **People own the documents.** Generated docs are markdown in git that people review and edit; the index is a rebuildable cache ([ADR 0006](decisions/0006-markdown-for-humans-db-as-cache.md)).
- **Open and permissive.** RepoRanger is MIT-licensed, and copyleft tools run only as optional external processes ([ADR 0007](decisions/0007-permissive-licensing.md)).

## Who it's for

- Developers and teams who maintain many repositories, starting with C#/.NET, TypeScript/JavaScript, and Python codebases.
- Coding agents (Claude Code, Cursor, and others) that need precise, cheap repository context through MCP.
- Tech leads and stakeholders who need business-facing docs, audit summaries, and a backlog they can act on.

## Where it's different

Open-source tools already cover developer wikis, LLM packaging, security scanning, code review, and code indexing. Code indexing is the most crowded category of all, with several projects above 30k stars, and some tools (repowise, tokensave, trace-mcp) also compute git-history signals. The [landscape research](research/oss-landscape-2026-09.md) found two gaps. No MIT-licensed tool offers code graph, history, and health in one queryable, evidence-backed store; the one that does is AGPL. And no tool at all produces business documentation, observability and KPI recommendations, or a backlog generated from findings. So RepoRanger's index is deliberately thin, importing precise code structure from compiler-backed SCIP indexes ([ADR 0011](decisions/0011-scip-first-extraction.md)), and its product is the lenses.

## Delivery surfaces

1. **CLI** first: runs locally and in CI.
2. **MCP server** second: the same queries, exposed to coding agents.
3. **Web UI** last: views over findings, plus administration of model roles.

The MVP ships the CLI and the MCP server.

## Open-source goals

RepoRanger is a personal open-source project, and the repository should look intentional from the first commit: a one-command install, demo repositories, and, once the Documentation module exists, RepoRanger's own docs generated by RepoRanger.

## Non-goals for now

- **Implementing observability.** The observability module produces a recommendations document, not instrumentation.
- **LLM entity extraction over code** ("full" GraphRAG). Code already has a deterministic graph ([ADR 0003](decisions/0003-retrieval-graph-fts-graphrag-lite.md)).
- **A free-form "pick any database" setting.** Storage is pluggable by capability and profile ([ADR 0004](decisions/0004-storage-abstraction-by-capability.md)).
- **A web UI in the MVP.**
