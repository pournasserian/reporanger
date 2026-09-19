# ADR 0005: SQLite for the MVP

- **Status:** Accepted
- **Date:** 2026-09-18

## Context

The MVP needs one embedded store per repository that holds nodes with variable attributes, edges with traversal, ranked full-text search, cached summaries, and later vectors. It must need no separate install, work the same from C#, TypeScript, and Python (the stack is undecided), and produce a portable file.

| Need | SQLite | Plain files (JSON/Parquet) | MongoDB | PostgreSQL | SQL Server | DuckDB |
| --- | --- | --- | --- | --- | --- | --- |
| Zero install, single file per repo | ✅ | ✅ | ❌ server | ❌ server | ❌ server | ✅ |
| 1–3 hop graph queries (indexed joins) | ✅ | ❌ app code | ⚠️ `$graphLookup` | ✅ | ✅ | ✅ |
| Deeper traversal with a depth cap | ✅ recursive queries | ❌ | ⚠️ | ✅ | ✅ | ✅ |
| Ranked full-text search | ✅ FTS5 built in | ❌ | ⚠️ server text index | ✅ | ✅ | ⚠️ extension |
| Documents (JSON attributes, summaries) | ✅ JSON columns | ✅ | ✅ | ✅ JSONB | ✅ | ✅ |
| Vector search later | ✅ extension | ❌ | ⚠️ Atlas only | ✅ pgvector | ⚠️ 2025+ | ✅ extension |
| Same engine from C#, TypeScript, Python | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| Portable snapshot or demo bundle | ✅ copy the file | ✅ | ❌ | ❌ | ❌ | ✅ |
| Multi-user concurrent writes | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |

## Decision

SQLite is the only MVP engine (the Embedded profile). One file per repository holds nodes with JSON attributes, typed and weighted edges with provenance, an FTS5 full-text index, the summaries cache, and history tables. A vector extension is added when semantic search arrives in P2.

## Consequences

- The index is a portable artifact: copy it, diff two snapshots, ship pre-indexed demo repos, attach one to a bug report, or delete it and rebuild from source.
- Graph-as-tables is unglamorous but debuggable. Variable-length path queries are clumsier than in Cypher, so the MVP caps traversal depth and offers no arbitrary path-finding.
- Graph algorithms (community detection, PageRank) run in memory at index time and write their results back as node attributes.
- Concurrent writers are limited. That is fine for a CLI or an MCP process, but not for a multi-user server, and it is the trigger for the Server profile.

Where the other options fit:

- **PostgreSQL:** the Server profile (P2). It has the same relational + JSONB + full-text + pgvector shape, so the SQLite adapter ports almost one-to-one.
- **DuckDB:** worth a look only if history analytics (churn and coupling over millions of commits) become a bottleneck. That is more likely now that full history is the default ([MVP decision 1](../modules/01-ingest-and-index/mvp-brief.md#decisions-confirmed-2026-09-19)).
- **MongoDB, SQL Server:** community adapters.
- **Plain files:** export/import bundles and the markdown layer, not the query store.
- **Neo4j:** an optional adapter for deep traversals, cross-repo graphs at scale, or Cypher; deferred.
- **Kuzu:** an attractive embedded graph database, but its open-source maintenance reportedly stopped in late 2025, and its LadybugDB fork is young. Avoided.
