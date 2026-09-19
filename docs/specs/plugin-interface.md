# Plugin interface: extractors and indexers

**Status:** Proposed · **Last updated:** 2026-09-19

This is the contract for Module 1's extraction plugins. It says what each kind of plugin receives, what it returns, and what the core builds from it. P0 defines the contract and P1 publishes it for community plugins, as the [MVP brief](../modules/01-ingest-and-index/mvp-brief.md#p0-feature-list) plans. [plugin-facts.json](plugin-facts.json) holds the JSON Schema for every message and fact.

The contract builds on:
- the [index schema](index-schema.sql)
- [ADR 0011](../decisions/0011-scip-first-extraction.md) (SCIP-first extraction)
- [ADR 0012](../decisions/0012-resolution-levels-for-every-edge.md) (resolution levels)
- [ADR 0013](../decisions/0013-syntax-pass-on-every-code-file.md) (the syntax pass)
- [ADR 0014](../decisions/0014-symbol-id-scheme.md) (symbol IDs)
- [ADR 0015](../decisions/0015-any-parser-that-passes-the-fixtures.md) (any parser that passes the fixtures)

Nothing here depends on the language a plugin or the core is written in.

## Contents

1. [Plugin kinds](#1-plugin-kinds)
2. [Protocol](#2-protocol)
3. [Syntax facts](#3-syntax-facts)
4. [Rules per language](#4-rules-per-language)
5. [Metrics](#5-metrics)
6. [What the core builds from syntax facts](#6-what-the-core-builds-from-syntax-facts)
7. [SCIP indexers and the importer](#7-scip-indexers-and-the-importer)
8. [Fallback resolution](#8-fallback-resolution)
9. [Manifest extractors](#9-manifest-extractors)
10. [Conformance and versions](#10-conformance-and-versions)

## 1. Plugin kinds

| Kind | One per | Receives | Returns |
| --- | --- | --- | --- |
| Syntax extractor | Language | The text of files | Declarations, call sites, imports, test and entry-point markers, metrics, parse errors |
| SCIP indexer | Language and build system | A project | An `index.scip` file, which the core's SCIP importer reads. A descriptor (section 7.1) tells the core how to run it |
| Manifest extractor | Package ecosystem | Manifests and lockfiles | Projects, declared dependencies, locked packages, package entry points |

Everything else is core: every implementation provides it the same way. The core covers:
- discovery and content hashes
- the SCIP importer (section 7.3) and fallback resolution (section 8)
- symbol IDs and merging (section 6)
- test-to-code mapping, git history, and structure (communities, importance)
- the sensitivity policy
- writing the index

A new language needs a syntax extractor, plus a SCIP indexer if one exists for it. P1 adds analyzer plugins for framework facts, such as endpoints and dependency-injection registrations.

Built-in extractors may run inside the core's process. They must still produce exactly the facts an out-of-process extractor would, and the same fixtures check them (section 10).

## 2. Protocol

- **Transport:** the core starts the plugin as a child process and speaks JSON-RPC 2.0 over its standard input and output. Each message is one line of UTF-8 JSON with no embedded newlines, as in MCP's stdio transport. Standard error is for logs only; the core may record them but never parses them.
- **Flow:** the core sends one request at a time and waits for its response. For parallelism it may start the same plugin more than once.
- **Lifecycle:** `initialize`, then any number of work requests, then a `shutdown` request, then an `exit` notification.

| Method | Plugin kind | Params | Result |
| --- | --- | --- | --- |
| `initialize` | all | Protocol version; the core's name and version | Protocol version; the plugin's name and version; its kind; the languages or ecosystems it handles, with their file patterns; its facts version |
| `extract` | syntax | A batch of files: path, language, text | One set of facts per file, in the same order (section 3) |
| `extract_manifests` | manifest | Every file matching the plugin's manifest patterns: path, text | Projects, dependencies, locked packages, package entries (section 9) |
| `shutdown` | all | none | `null` |
| `exit` | all | notification, no response | – |

The rules:
- **Parse failures:** a file the extractor can't fully parse still gets facts for whatever it could read, plus `errors`. JSON-RPC errors are only for protocol failures: unknown methods, malformed params, or a batch the plugin can't process at all.
- **Crashes and timeouts:** when a plugin crashes, exits, or passes its configured timeout, the core ends the process. It records `analyzer_degraded` on the affected files or projects and carries on without those facts.
- **Determinism:** the same input always gives the same output. Plugins read no clock, use no randomness, and make no network calls.
- **Input text:** plugins receive each file's text as the core hashed it: decoded from UTF-8, or from UTF-16 when a byte-order mark says so, with LF line endings. The text is not redacted, because extraction needs the real code. Plugins must not store it or send it anywhere.

## 3. Syntax facts

`extract` returns one object per file. The full schema is `file_facts` in [plugin-facts.json](plugin-facts.json).

**Positions.** A position has a line, 1-based as in the index, and a column, 0-based and counted in UTF-8 bytes from the start of the line. A range is `[start_line, start_col, end_line, end_col]`, and its end is exclusive.

| Field | Holds |
| --- | --- |
| `declarations` | Every declaration that becomes a node, in source order (below) |
| `call_sites` | The name range of each call's callee: every invocation; object creation (the call goes to the constructor); in C#, `base(...)` and `this(...)` constructor initializers. For `a.b.c()` the range covers `c` |
| `imports` | Each import: its module (as written), the names it imports, its kind (`relative`, `absolute`, or `namespace`), and its line |
| `lines`, `loc` | The file's physical lines, and the lines that hold more than whitespace and comments |
| `test` | Whether the file is a test file (section 4.5) |
| `entry_point` | `main` when the file is a program entry point (section 4.5) |
| `errors` | Parse errors, each with a line and a message |

A declaration has these fields:

| Field | Holds |
| --- | --- |
| `kind` | Its fine kind (section 4.1) |
| `name`, `qualified_name` | Its name, with the special names of section 4.2, and the qualified name used in its ID |
| `overload_identity` | For C# methods, constructors, operators, and indexers: the string defined in [index-schema.sql](index-schema.sql), section 3. Otherwise null |
| `parent` | The index of the enclosing declaration in this list, or null |
| `span` | From the first line of its doc comment, attribute, or decorator (whichever comes first) to the end of its last token |
| `name_range` | Its name alone. For constructors, the type name as written; for indexers, the `this` keyword; for operators, the `operator` keyword |
| `signature`, `doc` | Section 4.4 |
| `visibility`, `modifiers` | Section 4.4 |
| `metrics` | `loc` always; `complexity`, `nesting`, and `params` for methods, constructors, finalizers, operators, and functions (section 5) |
| `test`, `entry_point` | Section 4.5 |
| `merge` | True when the language treats this declaration and others of the same name as one symbol (section 4.6) |
| `has_body` | False for overload signatures, abstract and interface members, and C# partial methods declared without an implementation. Merging uses it to find the implementation |

The extractor reports components; it never builds IDs. The core builds them (section 6).

## 4. Rules per language

### 4.1 Fine kinds

| Declaration | C# | TypeScript / JavaScript | Python |
| --- | --- | --- | --- |
| Types | class, interface, struct, `record` or `record class` or `record struct` → record, enum, delegate | class, interface, enum; `type X =` → type_alias | class; `type X =` → type_alias |
| Callables | method; constructor; static constructor → constructor; finalizer; operator, including conversions | function declaration → function; class and interface methods → method; constructor | `def` at module level → function; `def` in a class → method; `__init__` → constructor |
| Values | property; indexer; each declarator of a field declaration → field, or constant when declared `const`; event; enum member | class fields, accessors, and parameter properties → property; interface properties → property; module-level `const`, `let`, and `var` declarators → variable; enum member | assignment in a class body → field; `@property` → property; assignment at module level → variable, or constant when the name is all capitals, digits, and underscores |
| Function-valued | – | a variable or property whose initializer is an arrow function or a function expression → function at module level, method in a class | – |
| Special | positional parameters of a record → property | – | – |
| Not nodes | namespaces, local functions, lambdas, property accessors, primary-constructor parameters of classes | namespaces and modules (they only qualify names), object-literal members, anything inside a function body | nested `def`s, lambdas, anything inside a function body |

### 4.2 Names and qualified names

- **C#:** the enclosing namespaces (file-scoped or block, nested ones joined), then the enclosing types, then the name, joined with `.`.
  - A generic type's name ends in a backtick and its own type-parameter count: ``Outer`1.Inner`1``.
  - Special names: constructor `<ctor>`, static constructor `<cctor>`, finalizer `<finalizer>`, indexer `this[]`.
  - An operator takes the metadata name the C# compiler emits, such as `op_Addition`, `op_Equality`, `op_Implicit`, or `op_Explicit`.
  - An explicit interface implementation is named `<interface as written>.<member>`, as in `IDisposable.Dispose`.
- **TypeScript and JavaScript:** the enclosing namespaces (`namespace A.B` contributes `A.B`; `declare module "x"` contributes `"x"` with its quotes), then the enclosing classes or interfaces, then the name. Module scope contributes nothing.
  - A computed member name is written as in the source, brackets included: `[Symbol.iterator]`.
  - A private name keeps its `#`.
  - A constructor is named `constructor`, and an anonymous default export `default`.
- **Python:** the enclosing classes, then the name, as written, dunders included.

### 4.3 Overload identity

C# only. The identity is exactly the string that [index-schema.sql](index-schema.sql), section 3, defines, and the core hashes it into the signature hash. Extractors for other languages report `null`.

### 4.4 Signature, doc comment, visibility, modifiers

**Signature.** It covers the declaration's text from its first modifier or keyword up to, but not including, its body, initializer, accessor list, or expression body. Doc comments, attributes, and decorators are left out. Runs of whitespace, newlines included, collapse to one space, and a trailing `{`, `:`, `=`, `=>`, or `;` is dropped. Examples:
- `public bool Login(string user, string password)`
- `export async function handler(req: Request): Promise<Response>`
- `def add_api_route(self, path, endpoint)`

| | C# | TypeScript / JavaScript | Python |
| --- | --- | --- | --- |
| Doc comment | The consecutive `///` lines directly above the declaration and its attributes, each without its `///` and one following space; or a `/** */` block in that place | The `/** */` block directly above the declaration and its decorators, without `/**`, `*/`, and each line's leading `*` | The docstring: the body's first statement when it is a string literal, with common indentation and surrounding blank lines removed |
| Visibility | As declared: `public`, `protected`, `internal`, `private`, `protected internal` → protected_internal, `private protected` → private_protected, `file` → module. Defaults when absent: members of classes, structs, and records → private; interface and enum members → public; top-level types → internal; nested types → private; explicit interface implementations → private | Class members as declared, public by default; `#name` → private; interface members → public. Top-level and namespace declarations: exported → public, otherwise module | A name starting with `_` → private, unless it both starts and ends with `__`; everything else public |
| Modifiers | Keywords other than visibility, in source order: `static`, `abstract`, `virtual`, `override`, `sealed`, `readonly`, `const`, `async`, `partial`, `extern`, `unsafe`, `new`, `required`, `volatile` | `static`, `abstract`, `async`, `readonly`, `declare`, `override`, `accessor`, `export`, `default`, and `get` or `set` for accessors | `async`, then each decorator's dotted name without `@` or arguments, in source order: `staticmethod`, `property`, `app.get` |

### 4.5 Tests and entry points

| | Tests | Entry points |
| --- | --- | --- |
| C# | Methods with `[Fact]`, `[Theory]`, `[Test]`, `[TestCase]`, `[TestCaseSource]`, `[TestMethod]`, or `[DataTestMethod]`; the classes that contain them; the files that contain them | A `static` method named `Main` → `main`; a file with top-level statements → the file is `main` |
| TypeScript / JavaScript | Files named `*.test.*` or `*.spec.*`, or under a `__tests__/` directory. Test cases are anonymous callbacks, so tests are file-level | None from syntax; `package.json` entries come from the manifest extractor |
| Python | Files named `test_*.py` or `*_test.py`, with the `test_*` functions and `Test*` classes in them; subclasses of `unittest.TestCase` anywhere, with their `test_*` methods | A module-level `if __name__ == "__main__":` → the file is `main` |

These lists are defaults. Configuration can add test attributes, test file patterns, and test base classes, for example for an in-house framework.

### 4.6 Merging

`merge` is true on declarations the language treats as one symbol:
- **C#:** types and methods with the `partial` modifier.
- **TypeScript:**
  - function and method overload signatures, together with their implementation
  - classes and interfaces, because an interface merges with same-named interfaces and with a class of the same name in the same scope
  - enums that share a name in the same scope
  - a getter and setter pair
- **Python:** every declaration, because binding a name twice in one scope leaves one symbol.

The core merges them as section 6 describes.

## 5. Metrics

One definition applies to every language, so hotspot scores compare fairly within a polyglot repository.

**Complexity** is 1 plus the number of decision points in the body. Decision points inside lambdas and local functions count toward the symbol that contains them.

| Language | Decision points, +1 each |
| --- | --- |
| C# | `if`; each `case` label that isn't `default`; each switch-expression arm that isn't a lone `_`; `for`, `foreach`, `while`, `do`; each `catch`; each `when` clause; `?:`; each `&&`, `\|\|`, `??`, and `??=` |
| TypeScript / JavaScript | `if`; each `case` that isn't `default`; `for`, `for...in`, `for...of`, `while`, `do`; each `catch`; `?:`; each `&&`, `\|\|`, `??`, `&&=`, `\|\|=`, and `??=` |
| Python | `if`, each `elif`; each `case` except `case _:`; `for`, `while`; each `except`; each conditional expression (`x if c else y`); each `and` and `or` operator; each `for` and `if` clause of a comprehension |

An `else` adds nothing, and an `else if` counts once, as its `if`.

- **Nesting** is the deepest nesting of control structures in the body. The control structures are the `if` chain (an `else if` continues it and doesn't deepen it), `switch` and `match`, loops, and `try`. A `catch` or `finally` sits at the level of its `try`. Lambdas and local functions are transparent: their control structures nest within the enclosing ones. A body without control structures has nesting 0.
- **LOC** counts the lines in the span that hold at least one character that is neither whitespace nor part of a comment. Doc comments are comments; attributes and decorators are code.
- **Params** counts declared parameters. In Python it leaves out the first parameter of a method (`self` or `cls`) unless the method is a `@staticmethod`, and counts `*args` and `**kwargs` as one each, but not the bare `*` and `/` markers. In TypeScript it leaves out a `this` parameter. In C# it counts every declared parameter, including the `this` of an extension method and a `params` array.

## 6. What the core builds from syntax facts

**IDs.** A declaration's ID is `<path>::<kind>::<qualified_name>`, with `#<sighash>` appended when `overload_identity` isn't null (ADR 0014, [index-schema.sql](index-schema.sql) section 3).
- `<kind>` maps the fine kind to its coarse kind.
- The signature hash is the first 8 hex characters of SHA-256 over the overload identity in UTF-8.
- For example, `(string,string)` hashes to `a71350d8`.

**Merging.** Declarations with `merge` true merge when they share a qualified name and a coarse kind. For C#, which has namespaces, that applies across the whole repository; for TypeScript, JavaScript, and Python, only within one file. The merged node takes its path, span, and kind from a primary declaration:

| Merge | Primary declaration |
| --- | --- |
| C# partial declarations | The one whose path sorts first by byte value, then the earliest in that file |
| TypeScript overloads | The implementation (the one with `has_body`), or else the first signature |
| Other TypeScript merges | The first in the file |
| Python | The last binding, which is the one in effect, except that a `@property` getter is primary over its setter and deleter |

The node's doc comment is the primary's, or else the first one found among the other declarations. Its metrics come from the first declaration with `has_body`, or from the primary when none has a body. `attrs.declarations` lists the other declarations' paths and line ranges.

**Collisions.** After merging, if two declarations in one file still produce the same ID, the one whose span starts first keeps it. The others get `~2`, `~3`, and so on.

**Nodes and edges.** Each declaration becomes a symbol node, with columns as the index schema defines:
- `symbol_kind` is the fine kind.
- `lines` come from the span.
- `content_hash` is the SHA-256 of the span's text.
- `name_words` follows the schema's splitting rule.
- `signature` and `doc` are redacted.
- `attrs` holds visibility, modifiers, metrics, declarations, and entry point.
- `is_test` comes from the `test` marker.

Declarations with no parent get a CONTAINS edge from their file, and each parent gets a CONTAINS edge to each child. The file node takes `lines`, `loc`, `test`, and `entry_point` from its facts. Each parse error becomes a `parse_error` diagnostic on its line.

**Provenance.** Facts from a plugin carry an extractor row named `syntax:<language>`, `manifest:<ecosystem>`, or `scip:<indexer>`. For syntax and manifest extractors, its version is the plugin's name and version, as `initialize` reports them. For a SCIP indexer, it is the tool name and version recorded in the index file.

## 7. SCIP indexers and the importer

### 7.1 Indexer descriptors

A descriptor tells the core how to run one SCIP indexer. The schema is `indexer_descriptor` in [plugin-facts.json](plugin-facts.json).

| Field | Holds |
| --- | --- |
| `name` | The indexer's name, as used in `scip:<name>` |
| `languages` | The languages its output covers |
| `project_patterns` | Globs for the manifest files that define a project it indexes |
| `tools` | The executables it needs, each with a command that prints its version |
| `command` | The command line as a list of arguments. Placeholders `{repo_root}`, `{project_dir}`, `{manifest}`, and `{output}` are filled in per project |
| `output` | Where the index file appears, with the same placeholders |
| `timeout_seconds` | How long one project may take |

The three concrete descriptors, for scip-dotnet, scip-typescript, and scip-python, are written in the M1 and M3 task specs. Those milestones run the indexers on the demo repositories first.

### 7.2 Running indexers

The core runs each descriptor once per project it detects, in the project's directory. Configuration may instead point a project to a pre-built `index.scip`.
- **Missing tool:** a project whose indexer's tools are missing gets `indexer_missing`.
- **Failed run:** a run that exits with an error, times out, or writes no index gets `indexer_failed`.

Either way the project falls back to its syntax facts (`attrs.extraction` = `fallback`), and its files get extraction `fallback`.

### 7.3 The importer

These rules turn SCIP output into nodes and edges. Every implementation applies them the same way.

1. **Positions.** Each SCIP document declares its position encoding: UTF-8, UTF-16, or UTF-32 code units, from a 0-based line. The importer converts every position to a 1-based line and a UTF-8 byte column, using the file's text.
2. **Documents.** Only documents for files in the index are read. The rest, such as generated sources, are skipped. A file of an indexed project that has no document gets extraction `fallback` and a `document_missing` diagnostic; a file with a document gets extraction `scip`.
3. **Attachment.** A definition occurrence of a non-local symbol attaches to the declaration whose `name_range` starts at the same position; a merged declaration matches at any of its sites. The node records the symbol in `scip_symbol`. A definition with no matching declaration is counted per file under `unmatched_definitions`.
4. **Skipped symbols.** Local symbols are skipped, and so are symbols whose last descriptor is a namespace, parameter, type parameter, meta, or macro.
5. **Occurrences.** Every other occurrence that isn't a definition becomes one edge:
   - **Source:** the innermost stored declaration whose span contains the occurrence, or else the file. Occurrences inside the source's own `name_range` are skipped.
   - **Target:** the node the symbol is attached to. Failing that, an external symbol node when the symbol has a package that no document in the index defines. Failing both, the occurrence is counted under `unresolved_references` and makes no edge.
   - **Type:** IMPORTS when the occurrence has SCIP's Import role, running from the file to the target's file, or to the external symbol's package when one is known. CALLS when the occurrence's range equals a call site's range. REFERENCES otherwise.
6. **Relationships.** An `is_implementation` relationship becomes INHERITS when both ends are classes, records, or structs, and IMPLEMENTS otherwise, which covers interfaces and members. Other relationship kinds make no edges.
7. **External symbols.**
   - `id` is `ext:` followed by the SCIP symbol without its scheme.
   - `name` is the last descriptor's name, and `qualified_name` the descriptor names joined with `.`.
   - `symbol_kind` is the SCIP kind when it maps to a fine kind (Class → class, Method → method, and so on), and NULL otherwise.
8. **Aggregation.** Edges are aggregated per source, type, target, and file:
   - `weight` counts the occurrences.
   - `sites` lists their lines in ascending order.
   - `line` is the first site.
   - `resolution` is `resolved`.

## 8. Fallback resolution

Projects without SCIP resolution get import edges only in P0; the fallback has no call resolution. Following ADR 0012, no fallback edge is `resolved`.

| Language | Import | Becomes |
| --- | --- | --- |
| TypeScript / JavaScript | A relative specifier (`./x`, `../y`) that names exactly one indexed file, trying the specifier as written and with the extensions `.ts`, `.tsx`, `.d.ts`, `.js`, `.jsx`, `.mjs`, `.cjs`, then `/index` with each of those extensions, in that order | IMPORTS to that file, `import-scoped` |
| | A bare specifier whose package name (`@scope/name` or `name`) is a dependency declared by the file's project | IMPORTS to that package, `import-scoped` |
| Python | A relative import (`from . import x`), resolved against the file's package directory to one file | IMPORTS to that file, `import-scoped` |
| | An absolute module `a.b.c` that is `a/b/c.py` or `a/b/c/__init__.py` under exactly one of the project's source roots (the project directory, and its `src/` when present) | IMPORTS to that file, `import-scoped` |
| | Otherwise, one indexed file anywhere whose path ends in `a/b/c.py` or `a/b/c/__init__.py` | IMPORTS to that file, `name-match` |
| | A top-level name that matches a declared dependency after normalization (lowercase, `-` as `_`) | IMPORTS to that package, `import-scoped` |
| C# | `using` directives | No edge: a namespace isn't a file |

An import none of these resolves makes no edge. It is counted under `unresolved_references`, except standard-library modules, which aren't counted.

## 9. Manifest extractors

`extract_manifests` returns four lists. Their schemas are in [plugin-facts.json](plugin-facts.json).

| List | Each item |
| --- | --- |
| `projects` | A manifest's path, the project's name, language, build system, declared target frameworks or runtimes, and whether it references a test framework |
| `dependencies` | The declaring project (its manifest path), ecosystem, package name, the version range as written, scope (`runtime`, `dev`, `test`, `build`, `optional`, `peer`), and `direct: true` |
| `locked` | A lockfile's resolved packages: ecosystem, name, version, and the packages each depends on |
| `package_entries` | A project's entry files: `package.json` `main`, `bin`, and `exports`; pyproject scripts |

From these the core builds the graph:
- **Projects:** a project node for each manifest (`project:<manifest path>`), with CONTAINS edges to the files under its directory that don't belong to a nested project.
- **Packages:** a package node per purl, with the version a lockfile resolves.
- **Dependencies:** DEPENDS_ON from each project to each declared package, with `declared`, `scope`, and `direct` in the edge attributes; and DEPENDS_ON between locked packages.
- **Entry points:** `package_entry` on each listed file.

P0 ships extractors for three ecosystems:
- **nuget:** `*.csproj`, `Directory.Packages.props`, `packages.lock.json`.
- **npm:** `package.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`.
- **pypi:** `pyproject.toml`, `requirements*.txt`, `poetry.lock`, `uv.lock`.

The exact parsing rules for each belong to the M3 task specs.

## 10. Conformance and versions

- **Conformance.** An extractor conforms when, for every golden fixture of its language (M0 item 5), its facts equal the expected facts once both are serialized as RFC 8785 canonical JSON. In-process extractors serialize their facts for the same comparison. Fixture index expectations test the core's rules in sections 6 to 8. Under ADR 0015, passing the fixtures is what makes a parser acceptable.
- **Versions.** `protocol_version` and `facts_version` are both 1. Any change to the messages or to the meaning of a fact increments the relevant one, and the core refuses a plugin whose versions it doesn't support, recording `analyzer_degraded`. While this document is Proposed, changes keep version 1, as with `schema_version`.
