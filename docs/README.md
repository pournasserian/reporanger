# RepoRanger documentation

RepoRanger is in the design phase. These documents are the source of truth for what it will do and why.

## Start here

1. [Vision](vision.md): the problem, the ten capabilities, principles, and non-goals.
2. [Feature groups](feature-groups.md): the eight modules and the ideas captured for each.
3. [Roadmap](roadmap.md): status, milestones, and open decisions.
4. [Glossary](glossary.md): the terms used across these docs.
5. [Development workflow](development-workflow.md): how milestones, contracts, tasks, and reviews fit together, and how Claude Code is used.

## Module 1 — Ingest & Index

- [MVP brief](modules/01-ingest-and-index/mvp-brief.md): scope, P0 features, acceptance criteria, and confirmed decisions.
- [Feature catalog](modules/01-ingest-and-index/feature-catalog.md): every Module 1 capability and idea, with its phase.
- [Design notes (draft)](modules/01-ingest-and-index/design-notes.md): the early technical sketch, input for the M0 contracts.

## Specs

The M0 contracts, written before any engine code ([development workflow](development-workflow.md#specs-in-the-repository)).

- [Index schema](specs/index-schema.sql): SQLite DDL for the index file, with the symbol-ID scheme, `schema_version`, and the index hash.
- [MCP tools](specs/mcp-tools/) and [shared MCP definitions](specs/mcp-meta.json): request and response schemas for the 14 tools, plus `_meta`, paging, errors, resources, and limits. The [usage guidance](specs/mcp-usage.md) holds the server instructions and the usage prompt.
- [Plugin interface](specs/plugin-interface.md) and its [message schema](specs/plugin-facts.json): syntax extractors, SCIP indexer descriptors, and manifest extractors; the rules for each language; and what the core builds from their facts.
- [Sensitivity rules](specs/sensitivity-rules.md) and the [rule set](specs/sensitivity-rules.json): what counts as a secret, how it is redacted or withheld, and where redaction runs.

## Decisions

- [Architecture decision records](decisions/README.md): one short record per decision, with its status.

## Research

- [Open-source landscape, September 2026](research/oss-landscape-2026-09.md): what exists, what to reuse, and where the gaps are.
