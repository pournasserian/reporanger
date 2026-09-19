# ADR 0016: Specify the storage capability interfaces with the Server profile

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

[ADR 0004](0004-storage-abstraction-by-capability.md) defines storage access by capability (NodeStore, EdgeStore, TextIndex, SummaryStore, and later VectorIndex), and its consequences say "The capability interfaces are part of the M0 contracts." The M0 plan in the [roadmap](../roadmap.md) never gave them an item, and the gap came to light while planning the plugin interface.

Meanwhile the M0 contracts already fix what the Embedded profile stores and answers. The [index schema](../specs/index-schema.sql) defines every table, and the [MCP contract](../specs/mcp-meta.json) defines every query result, including traversal semantics for `get_impact`, search semantics, and paging. The Embedded profile has one engine, SQLite ([ADR 0005](0005-sqlite-for-mvp.md)). The second engine, PostgreSQL for the Server profile, is P2.

## Decision

- The storage capability interfaces are specified when the Server profile is designed. At that point there are two engines to check the abstraction against.
- Until then, the index schema and the MCP contract are the storage contracts for P0.
- Implementations may still keep storage behind capability-shaped interfaces internally, as ADR 0004 intends. Those interfaces are implementation detail, not contract.

## Consequences

- This amends ADR 0004's consequence "The capability interfaces are part of the M0 contracts": read "part of the Server profile's contracts". The rest of ADR 0004 stands.
- M0 is complete without a storage capability spec.
- A community adapter written before the Server profile exists has no stable interface to target. That was never an M0 promise: adapters were expected alongside the Server profile anyway.
