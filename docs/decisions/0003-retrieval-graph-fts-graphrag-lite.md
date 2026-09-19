# ADR 0003: Graph and full-text retrieval are required; semantic search is deferred; GraphRAG-lite

- **Status:** Accepted
- **Date:** 2026-09-18

## Context

The question was whether RAG, BM25, or GraphRAG is required. Every feature asks one of three kinds of question of a repository. Large repositories don't fit in a context window even after compression (see the [research](../research/oss-landscape-2026-09.md#llm-friendly-packaging)).

## Decision

| Question type | Example | Technique | Status |
| --- | --- | --- | --- |
| Structural | What calls this? What depends on that? Which tests cover it? | Code graph: call, import, inheritance, dependency, and test edges | Required, P0 |
| Lexical | Where does this identifier, string, config key, or log message appear? | Full-text search with BM25-style ranking | Required, P0 |
| Semantic | Where is authentication handled? What does this module do for the business? | Embeddings (vector search) | Optional, P2 |

**Hierarchical summaries** complete the picture: symbol → file → module → repo, where modules come from community detection over the graph rather than folder names. This is the context-window strategy for large repositories. Summaries are required in P0 and generated lazily.

RepoRanger does **not** use Microsoft-style GraphRAG, where an LLM extracts entities and relations from text. Code already has a deterministic graph, and paying an LLM to rediscover it wastes money. RepoRanger keeps only community detection and hierarchical summaries: "GraphRAG-lite".

Lenses retrieve through **context packing**: a token-budgeted bundle of a symbol, its neighbors, relevant summaries, and evidence, instead of whole files or repositories.

## Consequences

- The MVP needs no embedding provider; semantic "ask the repo" waits for P2.
- Storage must serve indexed 1–3 hop joins and depth-capped deeper traversals ([ADR 0005](0005-sqlite-for-mvp.md)). The MVP acceptance criteria include a deep-traversal check.
- Graph storage is an implementation detail behind an interface ([ADR 0004](0004-storage-abstraction-by-capability.md)). A graph database is worth adding only for unbounded traversals, cross-repo graphs at scale, Cypher or visual exploration, or graph algorithms beyond community detection and PageRank.
