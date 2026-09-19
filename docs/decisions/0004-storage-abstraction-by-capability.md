# ADR 0004: Storage abstraction by capability, not by vendor

- **Status:** Accepted
- **Date:** 2026-09-18

## Context

The question was whether storage could be user-configurable across document databases (MongoDB, LiteDB) and relational databases. Some data is naturally document-shaped: node attributes that vary by kind, cached summaries, and later findings and generated docs.

But the index depends on three capabilities that vendors implement very differently: multi-hop traversal, ranked full-text search, and (later) vector search. LiteDB offers none of them natively. MongoDB offers `$graphLookup` and text search, but only as a server. SQLite has full-text search and recursive queries but no native graph.

A "support everything" layer ends up either lowest-common-denominator (traversal in application code, slow on big repos) or full of per-backend special cases. Every backend is also a row in the test matrix and a support burden for a small open-source project.

## Decision

- Define data access by capability: **NodeStore**, **EdgeStore** (with `traverse(depth)`), **TextIndex**, **SummaryStore**, and later **VectorIndex**.
- Adapters declare which capabilities they provide natively. A missing capability may be served by a documented fallback, such as in-memory adjacency for traversal, at a documented performance cost.
- Ship two **profiles**: Embedded (single file; laptop, CI, MCP) and Server (multi-user, team), with one engine per profile. The MVP ships Embedded only.
- Allow hybrids: documents (summaries, findings, generated docs) may go to a document store while graph and text stay in the engine that handles them. That is where MongoDB or LiteDB fit: as a document adapter, not as "the database".
- Backend choice is per profile, not a free-form per-user setting.
- Keep the contract small enough that a community member can write an adapter in a weekend.

## Consequences

- MVP engine: SQLite ([ADR 0005](0005-sqlite-for-mvp.md)). Planned Server adapter: PostgreSQL (P2).
- MongoDB, SQL Server, Neo4j, and others can be community adapters behind the same interfaces.
- The capability interfaces are part of the M0 contracts.
