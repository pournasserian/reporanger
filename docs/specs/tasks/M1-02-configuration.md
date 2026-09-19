# M1-02: Configuration and the registry

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Load, merge, and validate configuration, and produce the effective configuration that the index stores and hashes.
- **Depends on:** M1-01.
- **Spec references:** [config.md](../config.md) and [config.schema.json](../config.schema.json); [sensitivity-rules.json](../sensitivity-rules.json) for the user rules it embeds; [index-schema.sql](../index-schema.sql), section 5, for `config_hash`.
- **Files and interfaces:**
  - `src/RepoRanger.Core/Configuration/`: `ConfigLoader` (reads the registry and a repository file with Tomlyn, validates both against the schema, and reports a file and key on failure), `Layering` (the five layers, tables merging key by key and arrays accumulating), `EffectiveConfig` (the settings that shape the index) and its canonical JSON and `config_hash`.
  - `RepoRangerHome`: the `REPORANGER_HOME` variable, and the platform defaults in config.md section 1.
- **Out of scope:** registering repositories from the CLI (M1-10); running anything the configuration names.
- **Tests first:**
  - The documented examples in config.md, section 8, parse and validate.
  - Layering: a value set in three layers takes the highest one; arrays from two layers accumulate in order, without duplicates.
  - A repository file that names a plugin, an indexer, or `sensitivity.disable` is refused, and the message names the key.
  - An unknown key, a `version` other than 1, and a window with both `days` and `commits` are each refused.
  - `config_hash` is stable: the same settings in a different key order give the same hash, and any change to a setting that shapes the index changes it, while changing the refresh bound does not.
  - The pseudonymization key is read from the environment variable and never appears in the effective configuration; `pseudonym_key_set` reflects it.
- **Verification step:** `dotnet test --filter Configuration` passes, and a test writes the effective configuration of the fixture's settings twice, from different key orders, and asserts one `config_hash`.
- **Done when:** the verification step passes, the tests are committed, and the review has no open correctness findings.
