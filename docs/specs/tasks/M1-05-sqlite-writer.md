# M1-05: The index file

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Create an index file from the committed schema, write nodes, edges, chunks, and provenance into it in batches, and compute the index hash, so the same repository at the same commit always produces the same hash.
- **Depends on:** M1-03, M1-04.
- **Spec references:** [index-schema.sql](../index-schema.sql), sections 4 to 7; [ADR 0005](../../decisions/0005-sqlite-for-mvp.md) and [ADR 0004](../../decisions/0004-storage-abstraction-by-capability.md) for the capability interfaces the writer sits behind; [config.md](../config.md), section 6, for `config_hash`.
- **Files and interfaces:**
  - `src/RepoRanger.Core/Store/Sqlite/`: `SchemaInstaller` (runs `docs/specs/index-schema.sql` unchanged, as an embedded resource — the DDL is never retyped in code), `NodeWriter`, `EdgeWriter`, `ChunkWriter`, `Extractors` and `Diagnostics`, `MetaTable` (the `building` to `ready` lifecycle).
  - `src/RepoRanger.Core/Store/IndexHash.cs`: the Merkle hash of section 5 — per-file `facts_hash` leaves, the repository, signals, and history sections, rows canonicalized as RFC 8785 JSON, real numbers rounded to six significant digits.
  - The capability interfaces of ADR 0004 (`NodeStore`, `EdgeStore`, `TextIndex`) with the SQLite adapter behind them, and the Embedded profile declaring what it provides natively.
- **Out of scope:** reading (M1-10); history tables and signals (M3); incremental refresh (M4), beyond storing the content hashes that make it possible.
- **Tests first:**
  - A fresh file has the schema's `application_id` and `user_version`, every table STRICT, and `PRAGMA integrity_check` clean.
  - The ten invalid writes of the schema stay rejected through the writer, not only through raw SQL.
  - Deleting a file node cascades to its symbols, edges, chunks, and diagnostics, and leaves both full-text indexes consistent.
  - Two runs over the same synthetic facts give the same index hash; shuffling the input order does not change it; changing one file's facts changes that file's leaf and the root and nothing else.
  - A run interrupted between batches leaves `state = 'building'` with no index hash, and the next run starts over rather than reading a half-written file.
  - Chunks start on fifty-line boundaries, and the full-text triggers keep `symbol_fts` and `text_fts` in step with the tables.
  - A schema version other than the file's triggers a re-index, not a migration.
- **Verification step:** a test writes a synthetic index twice, from shuffled input, and prints the two equal index hashes and `PRAGMA integrity_check`; `dotnet test --filter Store` passes.
- **Done when:** the verification step passes, the tests are committed, and the review has no open correctness findings.
