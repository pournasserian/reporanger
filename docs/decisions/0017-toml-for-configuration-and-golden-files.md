# ADR 0017: TOML for the files people edit

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

Four M0 contracts defer values to "configuration": sensitivity rules, test markers, the refresh bound, the history window, include and exclude rules, and how the pseudonymization key is supplied. Nothing said what that file looks like. The [development workflow](../development-workflow.md) also named the golden samples `golden/<language>.yaml`.

A stack-neutral contract needs one format that .NET, TypeScript, and Python read alike:

- **YAML** is the usual choice for developer tooling, but parsers disagree. PyYAML implements YAML 1.1, where `no` is false and `1e3` is a string, while most JavaScript and .NET parsers implement 1.2, where they aren't. The same file can mean different things in two implementations of the same contract.
- **JSON** is read everywhere, and it is already the format of the schemas and the MCP and plugin messages. But it has no comments, and every backslash in a regex has to be doubled, which the sensitivity rules would inherit.
- **TOML 1.0** has one specification, explicit types, comments, and literal strings that keep backslashes as they are. Parsers exist under permissive licenses: Tomlyn (MIT) for .NET, smol-toml (MIT) for JavaScript, and `tomllib` in Python's standard library.

## Decision

- Files people write are TOML 1.0: `.reporanger.toml`, the registry, the golden samples `golden/<language>.toml`, and the fixture's expected counts and edges.
- Files that programs write and exchange stay JSON: the JSON Schemas, plugin messages, and MCP tool definitions.
- After parsing, TOML data is validated against a JSON Schema. RepoRanger's TOML files use no TOML date or time values, so the data maps onto the JSON model exactly.

## Consequences

- The development workflow's `golden/<language>.yaml` becomes `golden/<language>.toml`.
- Every implementation needs a TOML parser. Python has one in its standard library, so contract tests can validate these files without any dependency.
- Contributors can comment their configuration, and regexes in user rules need no escaping.
- RepoRanger reads no YAML, so the YAML 1.1 and 1.2 split can't reach the index.
