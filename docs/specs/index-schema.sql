-- RepoRanger index schema: SQLite DDL for one index file
-- Status: Proposed · Last updated: 2026-09-19
--
-- Schema version 1. This file is the contract for the index in the Embedded profile: one
-- SQLite file per repository and ref, written and read by any implementation. Nothing in it
-- depends on the language an implementation is written in. The C#/.NET reference
-- implementation (ADR 0010) follows it like any other.
--
-- It implements the MVP brief (../modules/01-ingest-and-index/mvp-brief.md) and ADRs 0003,
-- 0005, 0011, 0012, 0013, and 0014 (../decisions/). Terms follow ../glossary.md.
--
-- Contents
--   1. Requirements     4. schema_version    7. Tables: meta, extractors, nodes, edges,
--   2. Conventions      5. Index hash           chunks, full-text search, commits,
--   3. Node IDs         6. Rules                file_commits, tags, diagnostics


-- 1. Requirements -----------------------------------------------------------------------------
--
-- SQLite 3.38.0 or later, built with FTS5. Every regular table is STRICT. Writers turn on
-- foreign keys on every connection (PRAGMA foreign_keys = ON), because SQLite doesn't store
-- that setting in the file.


-- 2. Conventions ------------------------------------------------------------------------------
--
-- Lines         1-based. A range is start_line..end_line, both inclusive. No column offsets.
-- Paths         Relative to the repository root, '/'-separated, exactly as git stores them:
--               case-sensitive, no leading './'.
-- Times         Unix seconds, UTC. Commit times also keep their UTC offset, in minutes.
-- Hashes        Lowercase hex.
-- JSON          attrs columns hold objects with snake_case keys. sites, parents, and refs hold
--               arrays.
-- Vocabularies  Stored as text and enforced with CHECK constraints: node and symbol kinds in
--               lowercase, edge types in UPPER_SNAKE, and resolution levels as in the brief.
--               Languages use Language Server Protocol identifiers ('csharp', 'typescript',
--               'typescriptreact', 'javascript', 'javascriptreact', 'python', 'json', 'yaml',
--               'markdown', ...).
-- Numbers       Computed REAL values (importance, churn, hotspot, coupling degree) are rounded
--               to 6 significant digits before they are stored.
-- Redaction     Every free-text column (chunks.text, nodes.signature, nodes.doc,
--               commits.message, diagnostics.message) passes through the sensitivity rules
--               before it is written, so the file never holds a matched secret. Redaction
--               never adds or removes a line break. The rules and the redaction marker belong
--               to sensitivity-rules.md (M0, to come).
-- Provenance    Every node and edge names the extractor that produced it. Through file_key it
--               also names the file it came from, and line ranges and sites give the lines.
--               The commit of every fact is meta.indexed_commit. A file whose indexed content
--               differs from that commit has dirty = 1, for example an uncommitted edit that a
--               refresh picked up.


-- 3. Node IDs ---------------------------------------------------------------------------------
--
-- nodes.id is the stable ID that tools return and accept. IDs are opaque to clients: the
-- parts they are built from are stored in their own columns.
--
--   Kind        ID
--   repo        repo:<name>
--   project     project:<path of the manifest, or of the directory followed by '/'>
--   file        <path>
--   symbol      <path>::<kind>::<qualified name>[#<sighash>]
--   external    ext:<SCIP symbol without its scheme>
--   package     a package URL (purl)
--   community   community:<n>
--
-- Examples
--   repo:orleans
--   project:src/Orleans.Core/Orleans.Core.csproj
--   src/Orleans.Core/Grain.cs
--   src/Auth/LoginController.cs::type::MyApp.Auth.LoginController
--   src/Auth/LoginController.cs::method::MyApp.Auth.LoginController.Login#a71350d8
--   src/Caching/Cache.cs::type::MyApp.Caching.Cache`1
--   src/users/users.service.ts::method::UsersService.findOne
--   fastapi/routing.py::method::APIRouter.add_api_route
--   ext:nuget System.Console 8.0.0.0 System/Console#WriteLine(+11).
--   pkg:nuget/Newtonsoft.Json@13.0.3
--   pkg:npm/%40nestjs/core@10.3.0
--   community:3
--
-- A file path that starts with one of these prefixes (repo:, project:, ext:, pkg:,
-- community:) gets a leading './' in its ID. Package URLs follow the purl specification,
-- including its per-type normalization. Their version is the resolved one, and it is left out
-- when no lockfile resolves it. Communities are numbered from 1 by size in member files,
-- largest first, with ties broken by the smallest member path. The numbers change whenever
-- community detection runs again.
--
-- Symbol IDs (ADR 0014)
--
-- <path>            The ID of the file that declares the symbol. A symbol declared in several
--                   files (C# partial types and methods, TypeScript declaration merging) is one
--                   node, under the path that sorts first by byte value. attrs.declarations
--                   lists the other declarations.
-- <kind>            type, method, or term, derived from the fine kind in nodes.symbol_kind:
--                     type    class, interface, struct, record, enum, delegate, type_alias
--                     method  method, constructor, finalizer, operator, function
--                     term    property, field, constant, enum_member, event, indexer, variable
--                   Which declarations get which fine kind in each language is part of the
--                   syntax pass contract, in plugin-interface.md (M0, to come).
-- <qualified name>  The enclosing namespaces and types and the symbol's own name, as declared
--                   in source, joined with '.'. In Python, TypeScript, and JavaScript the file
--                   is the module, so module scope adds nothing. Special names:
--                     generic type          name`arity      Cache`1
--                     C# constructor        <ctor>          static: <cctor>; finalizer: <finalizer>
--                     C# indexer            this[]
--                     C# operator           metadata name   op_Addition, op_Implicit
--                     TS/JS constructor     constructor
--                     anonymous default     default         export default class { }
-- <sighash>         Only on C# methods, constructors, operators, and indexers, the members C#
--                   lets you overload. It is the first 8 hex characters of SHA-256 over this
--                   UTF-8 overload identity:
--                     [`<generic arity>](<parameter>,<parameter>,...)[-><return type>]
--                   The generic arity prefix appears only on generic methods. A parameter is
--                   written as its ref, out, or in modifier and a space, if it has one,
--                   followed by its type as written with all whitespace and every '?' removed.
--                   The return type is added for conversion operators only.
--                     void Login(string user, string password)     (string,string)
--                     T Get<T>(int id)                             `1(int)
--                     bool TryRead(ref Span<byte> b, int? n)       (ref Span<byte>,int)
--                     explicit operator long(Money m)              (Money)->long
--
-- Not nodes: locals, parameters, type parameters, namespaces, lambdas, nested functions, and
-- anything else declared inside a function body. Code outside any declaration, such as C#
-- top-level statements or Python module-level code, belongs to its file node.
--
-- Declarations that the language treats as one symbol are one node: partial declarations,
-- TypeScript overload signatures and merged declarations, and Python rebinding a name in the
-- same scope. When two other declarations in one file produce the same ID, the first in
-- source order keeps it, and the later ones get ~2, ~3, and so on appended.
--
-- A SCIP symbol that has a package but that no document in the index defines is an external
-- symbol. A symbol with an empty package, or a local symbol, that the index doesn't define is
-- unresolved: diagnostics count it, and no node is stored for it.


-- 4. schema_version ---------------------------------------------------------------------------
--
-- One integer, 1 for this file. It is stored in PRAGMA user_version, so a reader can check it
-- before touching any table, and mirrored in meta.schema_version. PRAGMA application_id
-- 0x52524958 ('RRIX') marks the file as a RepoRanger index.
--
-- The version goes up with any change to this file that alters the DDL or the meaning of a
-- stored value: the ID scheme, the hash algorithm, a vocabulary, an attribute key or its unit,
-- or the chunk size. A reader that finds any other version, older or newer, re-indexes. P0
-- has no migrations.


-- 5. Index hash -------------------------------------------------------------------------------
--
-- meta.index_hash is the root of a SHA-256 Merkle tree over the index's content. The same
-- commit, configuration, and extractor versions produce the same hash on any machine, and a
-- run that was interrupted and then rerun produces the same hash as one that wasn't. Each file
-- node stores its leaf in facts_hash. An incremental run therefore rehashes only the files it
-- touched, and comparing leaves shows which files' facts changed.
--
-- Rows. A hashed row is one line: RFC 8785 (JCS) canonical JSON of the row's fields, then LF.
-- The fields are the table's columns, with these changes:
--   - NULL fields are left out.
--   - JSON columns are embedded as JSON values.
--   - Each reference is replaced by a stable value, under the column's name without _key:
--     a node by its id, a commit by its sha, an extractor by "name@version".
-- Never hashed: the surrogate keys (node_key, chunk_key, commit_key, diag_key, extractor_key),
-- facts_hash, diagnostics.message, and meta. The chunks and full-text tables are derived from
-- hashed content, so they aren't hashed either. Each attrs key belongs either to its row or
-- to the signals section, as listed with the nodes table.
--
-- Leaves. For a file node F, facts_hash is SHA-256 over:
--   F's own row;
--   the rows of nodes whose file_key is F, by id;
--   the rows of edges whose file_key is F, by (src id, type, dst id);
--   the rows of diagnostics on F, by (code, line, severity).
--
-- Sections. Each is SHA-256 over its rows, in this order:
--   repo     the repo node's row; the rows of nodes whose file_key is the repo node, by id;
--            the rows of edges whose file_key is the repo node, by (src id, type, dst id);
--            the rows of diagnostics on nodes that aren't files, by (node id, code, line,
--            severity)
--   signals  for each node with signals keys, by id: {"id": <id>, <its signals keys>}
--   history  commits by sha, file_commits by (file id, commit sha), tags by name
--
-- Root. index_hash is SHA-256 over the following UTF-8 text. Every line ends in LF, and fields
-- are separated by one space, except for the tab between a file's id and its leaf:
--   reporanger-index-hash 1
--   schema_version <n>
--   config_hash <meta.config_hash>
--   indexed_commit <meta.indexed_commit, or - without git>
--   file <id><TAB><facts_hash>          one line per file node, by id
--   section repo <hash>
--   section signals <hash>
--   section history <hash>
--
-- Ordering compares strings by their UTF-8 bytes and numbers numerically, with NULL first.
-- Three rules keep the hash reproducible:
--   - Time-decayed signals measure age from meta.indexed_commit_time, never from the clock.
--   - Graph algorithms (community detection, importance) use a fixed seed and visit nodes in
--     id order.
--   - Computed REAL values are rounded (section 2).


-- 6. Rules ------------------------------------------------------------------------------------
--
-- Writers
--   Turn on foreign keys. Create the repo node first: every node other than a file or the
--   repo node refers to one of them through file_key.
--
--   Update nodes in place by id (INSERT ... ON CONFLICT (id) DO UPDATE). That way node keys,
--   and the edges that point at a node, survive re-extraction. Never use INSERT OR REPLACE on
--   nodes or chunks: REPLACE deletes rows without firing the delete triggers that keep
--   full-text search in sync, and it gives the row a new key.
--
--   Delete a node only when its id no longer exists. Foreign keys then remove its edges,
--   chunks, file_commits, and diagnostics. Recompute facts_hash for every file that lost
--   edges this way.
--
--   Commit per batch. meta.state stays 'building' until the last batch. The final transaction
--   sets index_hash, state = 'ready', and updated_at together.
--
--   Redact every free-text column before writing it (section 2).
--
--   Store one CO_CHANGES row per pair of files, with the smaller id (by byte value) as the
--   source.
--
-- Readers
--   Check application_id and user_version before reading anything else, and re-index on a
--   mismatch.
--
--   Treat state = 'building' as incomplete: a run is in progress, or it was interrupted.


-- 7. Tables -----------------------------------------------------------------------------------

PRAGMA encoding = 'UTF-8';
PRAGMA application_id = 1381124440;  -- 0x52524958, 'RRIX'
PRAGMA user_version = 1;             -- schema_version (section 4)
PRAGMA foreign_keys = ON;            -- per connection; every writer sets it again


-- meta: one row that describes the index.
-- history: 'full' is all history, 'window' is the configured window, 'shallow' is a shallow
-- clone whose history is cut short, and 'none' means no git history.
CREATE TABLE meta (
  singleton           INTEGER PRIMARY KEY CHECK (singleton = 1),
  schema_version      INTEGER NOT NULL CHECK (schema_version = 1),  -- mirrors user_version
  state               TEXT    NOT NULL CHECK (state IN ('building', 'ready')),
  index_hash          TEXT,     -- section 5; set when state becomes 'ready'
  repo_name           TEXT    NOT NULL,
  source              TEXT,     -- clone URL or origin remote with credentials removed; NULL if none
  ref                 TEXT,     -- branch, tag, or commit requested; NULL for the checked-out HEAD
  indexed_commit      TEXT,     -- full commit ID; NULL when the source isn't a git repository
  indexed_commit_time INTEGER,  -- its committer time: "now" for every time-decayed signal
  dirty               INTEGER NOT NULL CHECK (dirty IN (0, 1)),  -- 1 when any file node is dirty
  history             TEXT    NOT NULL CHECK (history IN ('full', 'window', 'shallow', 'none')),
  pseudonymized       INTEGER NOT NULL CHECK (pseudonymized IN (0, 1)),
  config_json         TEXT    NOT NULL,  -- the effective configuration that shapes the content,
                                         -- as RFC 8785 JSON; no secrets, no machine paths
  config_hash         TEXT    NOT NULL,  -- SHA-256 of config_json
  tool_version        TEXT    NOT NULL,  -- the implementation that wrote the index, and its version
  created_at          INTEGER NOT NULL,
  updated_at          INTEGER NOT NULL,  -- end of the last completed run; index age counts from it
  CHECK (index_hash IS NULL OR (length(index_hash) = 64 AND index_hash NOT GLOB '*[^0-9a-f]*')),
  CHECK (state = 'building' OR index_hash IS NOT NULL),
  CHECK (indexed_commit IS NULL
         OR (length(indexed_commit) IN (40, 64) AND indexed_commit NOT GLOB '*[^0-9a-f]*')),
  CHECK ((indexed_commit IS NULL) = (indexed_commit_time IS NULL)),
  CHECK (indexed_commit IS NOT NULL OR history = 'none'),
  CHECK (json_valid(config_json) AND json_type(config_json) = 'object'),
  CHECK (length(config_hash) = 64 AND config_hash NOT GLOB '*[^0-9a-f]*')
) STRICT;


-- extractors: the tools and stages that produce facts, for provenance.
-- Names: 'discovery' (repo, project, and file nodes); 'scip:<indexer>', for example
-- 'scip:scip-dotnet', with the version from the SCIP index's tool info; 'syntax:<language>'
-- (the syntax pass, ADR 0013); 'fallback:<language>' (name resolution for projects on the
-- fallback); 'manifest:<ecosystem>'; 'tests' (test-to-code mapping); 'git' (history);
-- 'structure' (communities, importance, entry points). For RepoRanger's own stages, the
-- version is the implementation's version, plus the parser grammar's version where one is used.
CREATE TABLE extractors (
  extractor_key INTEGER PRIMARY KEY,
  name          TEXT NOT NULL,
  version       TEXT NOT NULL,
  UNIQUE (name, version)
) STRICT;


-- nodes: everything the graph connects.
--   repo       the repository; exactly one
--   project    a buildable unit: a C# project, an npm package, a Python project
--   file       every file discovery found, skipped ones included (extraction, skip_reason)
--   symbol     a declaration in the repository, or an external symbol it references
--   package    a dependency from a manifest or lockfile
--   community  a module found by community detection over the files
CREATE TABLE nodes (
  node_key       INTEGER PRIMARY KEY,      -- internal: never returned by tools, never hashed
  id             TEXT    NOT NULL UNIQUE,  -- section 3
  kind           TEXT    NOT NULL
                   CHECK (kind IN ('repo', 'project', 'file', 'symbol', 'package', 'community')),
  symbol_kind    TEXT    CHECK (symbol_kind IN (
                   'class', 'interface', 'struct', 'record', 'enum', 'delegate', 'type_alias',
                   'method', 'constructor', 'finalizer', 'operator', 'function',
                   'property', 'field', 'constant', 'enum_member', 'event', 'indexer',
                   'variable')),
                           -- fine kind; NULL only for an external symbol whose kind SCIP omits
  name           TEXT    NOT NULL,
                           -- symbol: its declared name (section 3); file: the last path
                           -- segment; community: its label, the deepest directory that holds
                           -- all its files, or else the one that holds the most; others: their name
  qualified_name TEXT,     -- symbol: the qualified name from its ID; external: the SCIP
                           -- descriptor names joined with '.'
  name_words     TEXT,     -- symbol: its name split into words, for search (see symbol_fts)
  language       TEXT,     -- Language Server Protocol identifier
  file_key       INTEGER REFERENCES nodes (node_key) ON DELETE CASCADE,
                           -- provenance. Symbol: its declaring file. Project: its manifest.
                           -- Package, community, external symbol, project without a manifest:
                           -- the repo node. File and repo: NULL.
  start_line     INTEGER,  -- symbol: its declaration's span, including the doc comment and
  end_line       INTEGER,  -- any attributes or decorators
  content_hash   TEXT,     -- file: git blob ID of its content as git would store it
                           -- (git hash-object --path; of the raw bytes when there is no git).
                           -- symbol: SHA-256 of its span's text with LF line endings.
  signature      TEXT,     -- symbol: its declaration without the body, whitespace collapsed
  doc            TEXT,     -- symbol: its doc comment or docstring, comment markers removed
  scip_symbol    TEXT,     -- symbol: the SCIP symbol string, when SCIP defines or names it.
                           -- Not unique: scip-dotnet can emit the same string in two projects.
  is_external    INTEGER NOT NULL DEFAULT 0 CHECK (is_external IN (0, 1)),
  is_test        INTEGER NOT NULL DEFAULT 0 CHECK (is_test IN (0, 1)),  -- test file or symbol
  extraction     TEXT    CHECK (extraction IN ('scip', 'fallback', 'text', 'skipped')),
  skip_reason    TEXT    CHECK (skip_reason IN (
                   'generated', 'vendored', 'minified', 'binary', 'too_large', 'excluded',
                   'encoding')),
  sensitivity    TEXT    CHECK (sensitivity IN ('none', 'redacted', 'withheld')),
  dirty          INTEGER CHECK (dirty IN (0, 1)),
  facts_hash     TEXT,     -- file: its Merkle leaf (section 5)
  extractor      INTEGER NOT NULL REFERENCES extractors (extractor_key),
  attrs          TEXT    NOT NULL DEFAULT '{}',  -- keys listed after this table

  CHECK (json_valid(attrs) AND json_type(attrs) = 'object'),
  CHECK ((file_key IS NULL) = (kind IN ('repo', 'file'))),
  CHECK (kind = 'symbol'
         OR (symbol_kind IS NULL AND qualified_name IS NULL AND name_words IS NULL
             AND signature IS NULL AND doc IS NULL AND scip_symbol IS NULL AND is_external = 0)),
  CHECK (kind <> 'symbol' OR (qualified_name IS NOT NULL AND name_words IS NOT NULL)),
  CHECK (kind <> 'symbol' OR is_external = 1
         OR (symbol_kind IS NOT NULL AND start_line IS NOT NULL AND content_hash IS NOT NULL)),
  CHECK (is_external = 0
         OR (id GLOB 'ext:*' AND scip_symbol IS NOT NULL
             AND start_line IS NULL AND content_hash IS NULL)),
  CHECK (kind = 'file'
         OR (extraction IS NULL AND sensitivity IS NULL AND dirty IS NULL AND facts_hash IS NULL)),
  CHECK (kind <> 'file'
         OR (extraction IS NOT NULL AND sensitivity IS NOT NULL AND dirty IS NOT NULL)),
  CHECK ((extraction IS 'skipped') = (skip_reason IS NOT NULL)),
  CHECK (kind IN ('file', 'symbol') OR content_hash IS NULL),
  CHECK (kind <> 'file' OR extraction = 'skipped' OR content_hash IS NOT NULL),
  CHECK (is_test = 0 OR kind IN ('file', 'symbol')),
  CHECK ((start_line IS NULL) = (end_line IS NULL)),
  CHECK (start_line IS NULL OR (kind = 'symbol' AND start_line >= 1 AND end_line >= start_line)),
  CHECK (content_hash IS NULL
         OR (length(content_hash) IN (40, 64) AND content_hash NOT GLOB '*[^0-9a-f]*')),
  CHECK (facts_hash IS NULL OR (length(facts_hash) = 64 AND facts_hash NOT GLOB '*[^0-9a-f]*'))
) STRICT;

CREATE INDEX nodes_by_file        ON nodes (file_key);
CREATE INDEX nodes_by_kind        ON nodes (kind, symbol_kind);
CREATE INDEX nodes_by_name        ON nodes (name COLLATE NOCASE);
CREATE INDEX nodes_by_scip_symbol ON nodes (scip_symbol) WHERE scip_symbol IS NOT NULL;

-- attrs keys. "row" keys are hashed with the node's row. "signals" keys are derived from
-- history and structure, and are hashed in the signals section (section 5). Formulas and
-- detection rules marked M2 or M3 are fixed by those milestones' task specs; changing one
-- after that bumps schema_version. Keys that don't apply are left out.
--
--   Kind       Key              Type           Hashed   Meaning
--   symbol     complexity       integer        row      cyclomatic complexity (callables)
--              nesting          integer        row      deepest nesting of control flow (callables)
--              loc              integer        row      lines in the span that aren't blank or only comments
--              params           integer        row      parameter count (callables)
--              visibility       text           row      public, protected, internal, private,
--                                                       protected_internal, private_protected, or
--                                                       module (not exported from its file)
--              modifiers        array of text  row      as declared: static, abstract, virtual,
--                                                       override, async, readonly, export, ...
--              declarations     array          row      the other declaration sites:
--                                                       [{"path", "start_line", "end_line"}]
--              importance       real           signals  PageRank-style score over the call graph,
--                                                       scaled so the highest is 1 (M2)
--              entry_point      text           signals  main or package_entry (M2)
--   file       lines            integer        row      physical lines in the stored text
--              loc              integer        row      lines that aren't blank or only comments
--                                                       (code files)
--              bytes            integer        row      size of the content as hashed
--              entry_point      text           signals  main or package_entry (M2)
--              commits          integer        signals  non-merge commits that touched the file
--              churn            real           signals  recency-weighted commits (M3)
--              age_days         integer        signals  days from the file's first commit to
--                                                       meta.indexed_commit_time
--              last_commit      text           signals  sha of the latest commit that touched it
--              bugfix_commits   integer        signals  commits with is_bugfix = 1 that touched it
--              hotspot          real           signals  decayed churn x complexity (M3)
--   project    extraction       text           row      scip or fallback
--              fallback_reason  text           row      the diagnostics code behind the fallback
--              indexer          text           row      the SCIP indexer that applies, e.g. scip-dotnet
--              build            text           row      build system: msbuild, npm, pnpm, poetry, ...
--              frameworks       array of text  row      target frameworks or runtimes as declared,
--                                                       e.g. net8.0
--   package    ecosystem        text           row      purl type: nuget, npm, or pypi
--              version          text           row      the resolved version, when a lockfile gives one
--   community  size             integer        row      member files
--
-- Visibility rules per language, like the fine kinds, are part of the syntax pass contract.


-- edges: typed, weighted relationships between nodes. Resolution levels follow ADR 0012.
--
-- file_key is the file whose content establishes the edge, or the repo node for edges that
-- are derived from history or structure:
--   CONTAINS      the file that declares the contained node; the repo node for
--                 repo -> project and community -> file
--   DEPENDS_ON    the manifest or lockfile
--   CO_CHANGES    the repo node
--   all others    the file where the evidence is
-- line is the first site in that file. sites lists every site line in ascending order,
-- without duplicates. Both are NULL for edges without a location. The source of a code edge
-- is the innermost enclosing node that is stored: a symbol, or the file for code outside any
-- declaration.
--
--   Type        From -> to                         Weight                        Resolution
--   CONTAINS    repo -> project, project -> file,  1                             resolved
--               file -> symbol, symbol -> symbol,
--               community -> file
--   IMPORTS     file -> file, file -> package      import statements             SCIP: resolved.
--                                                                                Fallback: import-scoped
--                                                                                (a relative path naming
--                                                                                one file) or name-match
--   CALLS       symbol|file -> symbol              call sites                    resolved (SCIP; the
--                                                                                fallback has no call
--                                                                                resolution in P0)
--   REFERENCES  symbol|file -> symbol              reference sites that          resolved (SCIP)
--                                                  aren't calls
--   INHERITS    type -> type                       1                             resolved (SCIP)
--   IMPLEMENTS  type -> type, member -> member     1                             resolved (SCIP)
--   TESTS       test symbol|file -> symbol|file    heuristics that agree, 1-3    the strongest evidence:
--                                                                                resolved call -> resolved,
--                                                                                import -> import-scoped,
--                                                                                naming -> name-match
--   DEPENDS_ON  project -> package,                1                             resolved
--               package -> package
--   CO_CHANGES  file -> file                       coupling degree:              resolved
--                                                  2 x shared commits /
--                                                  (commits of source +
--                                                  commits of target), 0-1
--
-- A call site is CALLS and never also REFERENCES. The syntax pass tells calls from other
-- references (ADR 0013). IMPLEMENTS also covers a member that implements or overrides
-- another, because SCIP doesn't tell the two apart.
--
-- Edge attrs:
--   DEPENDS_ON  {"declared": the version range as written,
--                "scope": "runtime" | "dev" | "test" | "build" | "optional" | "peer",
--                "direct": true when a manifest declares it}
--   CO_CHANGES  {"shared": commits that touched both files}
--   TESTS       {"evidence": a non-empty subset of ["call", "import", "naming"]}
CREATE TABLE edges (
  src_key    INTEGER NOT NULL REFERENCES nodes (node_key) ON DELETE CASCADE,
  type       TEXT    NOT NULL CHECK (type IN (
               'CONTAINS', 'IMPORTS', 'CALLS', 'REFERENCES', 'INHERITS', 'IMPLEMENTS', 'TESTS',
               'DEPENDS_ON', 'CO_CHANGES')),
  dst_key    INTEGER NOT NULL REFERENCES nodes (node_key) ON DELETE CASCADE,
  file_key   INTEGER NOT NULL REFERENCES nodes (node_key) ON DELETE CASCADE,
  resolution TEXT    NOT NULL CHECK (resolution IN ('resolved', 'import-scoped', 'name-match')),
  weight     REAL    NOT NULL CHECK (weight > 0),
  line       INTEGER CHECK (line >= 1),
  sites      TEXT    CHECK (json_valid(sites) AND json_type(sites) = 'array'),
  extractor  INTEGER NOT NULL REFERENCES extractors (extractor_key),
  attrs      TEXT    CHECK (json_valid(attrs) AND json_type(attrs) = 'object'),
  PRIMARY KEY (src_key, type, dst_key, file_key),
  CHECK ((line IS NULL) = (sites IS NULL)),
  CHECK (type <> 'CO_CHANGES' OR weight <= 1),
  CHECK (type NOT IN ('CONTAINS', 'DEPENDS_ON', 'CO_CHANGES') OR resolution = 'resolved')
) STRICT, WITHOUT ROWID;

CREATE INDEX edges_by_dst  ON edges (dst_key, type, src_key);
CREATE INDEX edges_by_file ON edges (file_key);


-- chunks: the stored text of every indexed text file, in fixed 50-line windows.
-- The text is the file's content as hashed, decoded from UTF-8 (or from UTF-16 when a
-- byte-order mark says so), with CRLF and lone CR turned into LF, and then redacted (section
-- 2). Lines are the text split at LF, and a final LF doesn't start another line. Chunk n,
-- counting from 0, holds lines 50n+1 to 50n+50 joined with LF, without a trailing LF. Files
-- with extraction 'skipped' or sensitivity 'withheld' have no chunks, and neither does an
-- empty file.
CREATE TABLE chunks (
  chunk_key  INTEGER PRIMARY KEY,
  file_key   INTEGER NOT NULL REFERENCES nodes (node_key) ON DELETE CASCADE,
  start_line INTEGER NOT NULL CHECK (start_line >= 1 AND start_line % 50 = 1),
  text       TEXT    NOT NULL,
  UNIQUE (file_key, start_line)
) STRICT;


-- Full-text search (FTS5). Both tables use external content and are kept in sync by the
-- triggers below, so writers only write nodes and chunks.
--
-- symbol_fts: word search over symbols. name_words is the symbol's name split into words,
-- lowercased (Unicode simple lowercase mapping), and joined with single spaces. The name is
-- split at every character that isn't a letter or a digit (the character is dropped), between
-- a lowercase letter or digit and an uppercase letter, and between two uppercase letters when
-- a lowercase letter follows the second:
--   GetUserById -> get user by id     HTTPServer -> http server     user_id -> user id
--   Base64Encode -> base64 encode     <ctor> -> ctor                Cache`1 -> cache 1
CREATE VIEW symbol_text AS
  SELECT node_key, name_words, qualified_name, signature, doc FROM nodes WHERE kind = 'symbol';

CREATE VIRTUAL TABLE symbol_fts USING fts5 (
  name_words, qualified_name, signature, doc,
  content = 'symbol_text', content_rowid = 'node_key',
  tokenize = 'unicode61 remove_diacritics 2'
);

-- text_fts: substring search over the stored text. The trigram tokenizer matches any
-- substring of three or more characters, ignoring case, and also serves LIKE and GLOB.
CREATE VIRTUAL TABLE text_fts USING fts5 (
  text,
  content = 'chunks', content_rowid = 'chunk_key',
  tokenize = 'trigram'
);

CREATE TRIGGER nodes_fts_insert AFTER INSERT ON nodes WHEN new.kind = 'symbol' BEGIN
  INSERT INTO symbol_fts (rowid, name_words, qualified_name, signature, doc)
  VALUES (new.node_key, new.name_words, new.qualified_name, new.signature, new.doc);
END;

CREATE TRIGGER nodes_fts_delete AFTER DELETE ON nodes WHEN old.kind = 'symbol' BEGIN
  INSERT INTO symbol_fts (symbol_fts, rowid, name_words, qualified_name, signature, doc)
  VALUES ('delete', old.node_key, old.name_words, old.qualified_name, old.signature, old.doc);
END;

CREATE TRIGGER nodes_fts_update
AFTER UPDATE OF node_key, kind, name_words, qualified_name, signature, doc ON nodes BEGIN
  INSERT INTO symbol_fts (symbol_fts, rowid, name_words, qualified_name, signature, doc)
  SELECT 'delete', old.node_key, old.name_words, old.qualified_name, old.signature, old.doc
  WHERE old.kind = 'symbol';
  INSERT INTO symbol_fts (rowid, name_words, qualified_name, signature, doc)
  SELECT new.node_key, new.name_words, new.qualified_name, new.signature, new.doc
  WHERE new.kind = 'symbol';
END;

CREATE TRIGGER chunks_fts_insert AFTER INSERT ON chunks BEGIN
  INSERT INTO text_fts (rowid, text) VALUES (new.chunk_key, new.text);
END;

CREATE TRIGGER chunks_fts_delete AFTER DELETE ON chunks BEGIN
  INSERT INTO text_fts (text_fts, rowid, text) VALUES ('delete', old.chunk_key, old.text);
END;

CREATE TRIGGER chunks_fts_update AFTER UPDATE OF chunk_key, text ON chunks BEGIN
  INSERT INTO text_fts (text_fts, rowid, text) VALUES ('delete', old.chunk_key, old.text);
  INSERT INTO text_fts (rowid, text) VALUES (new.chunk_key, new.text);
END;


-- commits: the commit graph within the history window.
-- Identities are resolved through the repository's .mailmap. When meta.pseudonymized = 1,
-- every name and email is replaced by 'anon-' followed by the first 12 hex characters of
-- HMAC-SHA-256(key, lowercased email). The key comes from configuration and is never stored.
-- Identity trailers in messages (Signed-off-by, Co-authored-by) are replaced the same way.
-- refs lists the PR and issue references found in the message, in order of appearance:
--   [{"kind": "pr" | "issue" | "unknown", "ref": "#123" or "owner/repo#123", as written}]
-- is_bugfix marks a message that describes a bug fix. P0 detects it from messages only, with
-- rules fixed by the M3 history task spec and the configuration.
CREATE TABLE commits (
  commit_key      INTEGER PRIMARY KEY,
  sha             TEXT    NOT NULL UNIQUE,
  parents         TEXT    NOT NULL,  -- JSON array of parent shas, in git's order
  author_name     TEXT    NOT NULL,
  author_email    TEXT    NOT NULL,
  author_time     INTEGER NOT NULL,
  author_tz       INTEGER NOT NULL,  -- UTC offset in minutes
  committer_name  TEXT    NOT NULL,
  committer_email TEXT    NOT NULL,
  committer_time  INTEGER NOT NULL,
  committer_tz    INTEGER NOT NULL,  -- UTC offset in minutes
  message         TEXT    NOT NULL,  -- the full message, redacted
  refs            TEXT    NOT NULL DEFAULT '[]',
  is_bugfix       INTEGER NOT NULL DEFAULT 0 CHECK (is_bugfix IN (0, 1)),
  CHECK (length(sha) IN (40, 64) AND sha NOT GLOB '*[^0-9a-f]*'),
  CHECK (json_valid(parents) AND json_type(parents) = 'array'),
  CHECK (json_valid(refs) AND json_type(refs) = 'array')
) STRICT;

CREATE INDEX commits_by_time ON commits (committer_time);


-- file_commits: which commits changed which current files. Renames are followed, so a file's
-- rows cover its earlier paths too. The history of files deleted before the indexed commit
-- is not kept, and merge commits have no rows.
-- change: A added, M modified, R renamed, C copied.
CREATE TABLE file_commits (
  file_key      INTEGER NOT NULL REFERENCES nodes (node_key) ON DELETE CASCADE,
  commit_key    INTEGER NOT NULL REFERENCES commits (commit_key) ON DELETE CASCADE,
  change        TEXT    NOT NULL CHECK (change IN ('A', 'M', 'R', 'C')),
  old_path      TEXT,     -- the file's path in that commit, when it differs from today's path
  lines_added   INTEGER CHECK (lines_added >= 0),    -- NULL for binary files
  lines_deleted INTEGER CHECK (lines_deleted >= 0),  -- NULL for binary files
  PRIMARY KEY (file_key, commit_key),
  CHECK ((lines_added IS NULL) = (lines_deleted IS NULL))
) STRICT, WITHOUT ROWID;

CREATE INDEX file_commits_by_commit ON file_commits (commit_key);


-- tags: tags whose target commit is in commits. Annotated tags are peeled to their commit.
CREATE TABLE tags (
  name       TEXT    PRIMARY KEY,
  commit_key INTEGER NOT NULL REFERENCES commits (commit_key) ON DELETE CASCADE
) STRICT;


-- diagnostics: what extraction missed or degraded, for the health report. The health report
-- is a query over these rows, over file nodes by extraction and skip_reason, and over project
-- nodes by attrs.extraction. There is one row per (node, code, line). line is NULL for a count
-- that covers the whole node.
--   parse_error            file     the syntax pass found syntax errors
--   indexer_failed         project  the SCIP indexer ran and failed; the project is on the fallback
--   indexer_missing        project  no SCIP indexer applies or is available; fallback
--   document_missing       file     the project's SCIP index has no document for the file; fallback
--   unresolved_references  file     references whose target is neither in the index nor external
--   analyzer_degraded      project  an extractor ran with reduced capability, for example
--                          or file  scip-python without a resolvable environment
CREATE TABLE diagnostics (
  diag_key  INTEGER PRIMARY KEY,
  node_key  INTEGER NOT NULL REFERENCES nodes (node_key) ON DELETE CASCADE,
                      -- a file, a project, or the repo node
  severity  TEXT    NOT NULL CHECK (severity IN ('error', 'warning', 'info')),
  code      TEXT    NOT NULL CHECK (code IN (
              'parse_error', 'indexer_failed', 'indexer_missing', 'document_missing',
              'unresolved_references', 'analyzer_degraded')),
  line      INTEGER CHECK (line >= 1),
  count     INTEGER NOT NULL DEFAULT 1 CHECK (count >= 1),
  message   TEXT,     -- redacted; not hashed
  extractor INTEGER NOT NULL REFERENCES extractors (extractor_key)
) STRICT;

CREATE UNIQUE INDEX diagnostics_identity ON diagnostics (node_key, code, ifnull(line, 0));
