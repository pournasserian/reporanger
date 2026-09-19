# ADR 0006: Markdown for human-facing docs; the index is a rebuildable cache

- **Status:** Accepted in principle; the details are designed in Module 2 (Documentation)
- **Date:** 2026-09-18

## Context

The question was whether RepoRanger's output should live in markdown files instead of, or alongside, a database. Markdown suits anything people read or edit, and it is mainly for team documentation. It fails for anything a machine must query. "Who calls this method across 20k files?" is a graph query, and ranked full-text search, vectors, concurrency, and hash-based invalidation all need an index.

## Decision

- Human-facing generated content is markdown with YAML frontmatter (source hashes, commit, model, prompt version, confidence), versioned in git.
- The index is a derived cache, always rebuildable from code and markdown. Delete the index and nothing is lost; delete the markdown and human edits and history are lost.
- Module 2 decides which artifacts become markdown and where they live. Candidate artifacts: module and file summaries, generated docs, findings, ADRs, and backlog items. Candidate locations: a tool-owned folder in the repository (working name `.reporanger/`) or a separate docs repository.

## Consequences

- Git brings diffs, blame, and pull-request review of generated content, which is a human-in-the-loop gate for free. The files also render on GitHub.
- Coding agents can read the folder directly, without a running MCP server (the "LLM wiki" pattern).
- A repository that ships its own generated docs is the best demo of the product.
- Existing markdown is input as well as output: Module 1 already ingests README files and ADRs as document nodes, which enables drift checks and reuse in business docs.
- Regeneration must preserve human edits: merge instead of overwrite, using a frontmatter hash of each generated section to detect what people changed.
