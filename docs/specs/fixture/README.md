# Fixture and golden samples

**Status:** Proposed · **Last updated:** 2026-09-19

The fixture is a small repository kept inside this one. It is the accuracy oracle: small enough to know by hand, and complete enough to exercise every rule the contracts state. This document designs it. The [golden schema](../golden/golden.schema.json) defines the files that hold its expectations, and the task specs build it: C# in M1, TypeScript and Python in M3.

## 1. What it proves

| Question | How the fixture answers it |
| --- | --- |
| Does extraction produce the right symbols and edges? | Every code edge is listed by hand in [`golden/<language>.toml`](../golden/csharp.toml), so precision and recall are exact, not sampled |
| Does a syntax extractor follow the rules? | The conformance cases in [`golden/syntax/`](../golden/syntax) pair a source file with its expected facts |
| Does the fallback work? | One project deliberately fails to build, so its files fall back to the syntax pass |
| Do secrets stay out? | The acceptance test plants generated secrets in a copy, indexes it, and checks every tool response |
| Are history signals right? | A scripted history is replayed into a temporary git repository, so commits, authors, and dates are known |
| Does incremental indexing hold? | Tests edit a copy, re-index, and compare the per-file hashes |

## 2. Layout

```
fixture/
  .reporanger.toml            settings the tests rely on
  history.toml                the scripted history (golden.schema.json, history_script)
  expected/
    csharp-counts.toml        known counts (golden.schema.json, expected_counts)
    typescript-counts.toml
    python-counts.toml
  csharp/
    Fixture.sln
    src/Shop/Shop.csproj      the library the golden edges cover
    tests/Shop.Tests/         xUnit tests, for test-to-code mapping
    broken/Broken.csproj      deliberately does not build
  typescript/                 package.json, tsconfig.json, src/, tests/
  python/                     pyproject.toml, shop/, tests/
```

The fixture is not indexed as part of RepoRanger's own repository: `.gitattributes` marks it, and the tests copy it to a temporary directory before indexing, so its planted placeholders and its scripted history never mix with this repository's own history.

## 3. What each language exercises

Every rule in the [plugin interface](../plugin-interface.md) needs a home. The conformance cases cover the syntax rules, and the projects cover everything that needs resolution, a build, or history.

| Area | Where |
| --- | --- |
| Fine kinds, names, special names, visibility, doc comments, modifiers, metrics, merging, call sites, imports | Conformance cases, one per language, extended as needed |
| Overloads and the signature hash | C# project: two `Add` overloads, a generic method, a conversion operator, an indexer |
| Partial declarations across files | C# project: `Order` in two files, with members in each |
| Records, enums, delegates, events, explicit interface implementations | C# project |
| TypeScript merging, overload signatures, arrow-valued members, default exports, namespaces | TypeScript project |
| Python rebinding, `@overload`, `@property` pairs, dunder names, `__main__` | Python project |
| External symbols | Every project calls into its platform library, so `ext:` nodes appear |
| Fallback resolution | `broken/`: its package reference cannot restore, so SCIP fails and the project falls back |
| Test-to-code mapping | Test projects that name, import, and call the code under test, one of each |
| Manifests and lockfiles | A committed lockfile per ecosystem, with one direct and one transitive dependency |
| History signals | `history.toml`: renames, a bug-fix message, two authors, and files that change together |
| Sensitivity | Placeholders for planted secrets, and literal placeholders that must not be redacted |

## 4. The project that does not build

`csharp/broken/Broken.csproj` references a package version that does not exist, so restore fails, `scip-dotnet` fails with it, and the project falls back to its syntax facts. The expected counts record the project as `fallback` with an `indexer_failed` diagnostic, and its files as `fallback` with no CALLS edges, which is what the P0 fallback produces.

## 5. Conformance cases

A case is a source file beside its expected facts:

```
golden/syntax/csharp/basics.cs        golden/syntax/csharp/basics.facts.json
golden/syntax/typescript/basics.ts    golden/syntax/typescript/basics.facts.json
golden/syntax/python/basics.py        golden/syntax/python/basics.facts.json
```

The facts file is a `file_facts` object from [plugin-facts.json](../plugin-facts.json). A test runs the extractor over the source and compares its output with the file, both as RFC 8785 canonical JSON. The three cases in this repository cover the rules an implementation meets first; M1 and M3 add cases with each language they bring, until every rule in sections 4 and 5 of the plugin interface has one. When an extractor and a case disagree, someone decides which is wrong and changes that one, in its own commit.

## 6. Planted secrets

The fixture holds placeholders, never secrets:

- `{{secret:<rule id>}}` marks where the acceptance test writes a generated fake secret, in a copy of the fixture.
- Literal placeholders such as `changeme` and `${API_KEY}` sit next to them, and must survive untouched.

So this repository holds no token-shaped strings, and the test still proves that every default rule catches its secret. The [sensitivity rules](../sensitivity-rules.md), section 10, describe the check.

## 7. Expectations

| File | Holds | Filled by |
| --- | --- | --- |
| `golden/<language>.toml` | Every code edge of that language's fixture project, by hand, and the sample judged on the demo repository | M1-09 (C#), M3 (others) |
| `fixture/expected/<language>-counts.toml` | Files by extraction status, symbols by kind, edges by type and resolution, diagnostics by code | The same tasks |
| `fixture/history.toml` | The commits a test replays | M3, with the history signals |

Changing the fixture means changing these files in the same commit. CI fails when a fresh index of the fixture differs from them, which is the point: a change in extraction has to be deliberate.

## 8. How CI uses it

1. Index a copy of the fixture.
2. Compare counts with `expected/<language>-counts.toml`.
3. Compare code edges with `golden/<language>.toml`, and require precision and recall at or above the file's thresholds, with the `absent` edges missing.
4. Run every conformance case against the syntax extractors.
5. Plant secrets in a copy, index it, and check that no planted secret appears in any tool response.

The demo repositories are not part of CI. Their judged samples run at release, as the [roadmap](../../roadmap.md) plans.
