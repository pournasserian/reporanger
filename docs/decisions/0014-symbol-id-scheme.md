# ADR 0014: Symbol IDs use a coarse kind, the qualified name, and a signature hash only for overloads

- **Status:** Accepted
- **Date:** 2026-09-19

## Context

The [MVP brief](../modules/01-ingest-and-index/mvp-brief.md#review-decisions-2026-09-19) (review item 20) requires symbol IDs that stay stable across re-indexing, built from path, kind, name, and a signature hash. The [design notes](../modules/01-ingest-and-index/design-notes.md#conceptual-graph-model) drafted `path::kind::name#signature-hash`, with an ID that changes whenever the signature changes. Work on the [index schema](../specs/index-schema.sql) found four problems with that draft:

- A simple name collides when two types in one file have members with the same name and signature.
- SCIP doesn't give fine kinds or full namespaces for C# ([ADR 0013](0013-syntax-pass-on-every-code-file.md)). Its descriptors reliably give only a coarse kind: type, method, or term.
- Hashing the whole signature changes the ID when a parameter is renamed or gets a default value. It also requires the fallback and SCIP paths to normalize signature text identically.
- Among the P0 languages, only C# has overloads, and scip-dotnet numbers them by declaration order.

## Decision

- An internal symbol's ID is `<path>::<kind>::<qualified name>[#<signature hash>]`, for example `src/Auth/LoginController.cs::method::MyApp.Auth.LoginController.Login#a71350d8`.
- `<kind>` is coarse: `type`, `method`, or `term`. The fine kind (class, interface, property, and so on) is stored separately.
- `<qualified name>` joins the enclosing namespaces and types and the symbol's own name with `.`, as declared in source. Generic types carry their arity in the name, as in ``Cache`1``.
- The signature hash appears only on members the language lets you overload. In P0 these are C# methods, constructors, operators, and indexers. The hash covers only what tells overloads apart: the method's generic arity and its parameter types as written, including `ref`, `out`, or `in`. It is the first 8 hex characters of SHA-256. Python and TypeScript symbols have no hash.
- An external symbol, meaning one defined outside the repository, has the ID `ext:` followed by its SCIP symbol without the scheme, version included.
- IDs are computed from source text by the syntax pass in both modes. The index schema holds the exact grammar, the special names, and the collision rules.

## Consequences

- This narrows review item 20: the signature hash is present only where overloads need it.
- An ID changes when a symbol moves, is renamed, changes its coarse kind, or (in C#) changes its parameter types.
- An ID survives body edits, parameter renames, and class-to-record or field-to-property changes. In Python and TypeScript it also survives any parameter change.
- Fallback and SCIP IDs agree, because every component comes from source text.
- Rewriting a C# parameter type in another style, such as `String` to `string`, changes that method's ID.
- External IDs change when the package version changes, and keep SCIP's order-based overload numbers.
- IDs are opaque to clients. Their components are stored in columns of their own.
