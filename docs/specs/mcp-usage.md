# RepoRanger MCP usage guidance

**Status:** Proposed · **Last updated:** 2026-09-19

This file holds the two texts that RepoRanger's MCP server gives to models, as [mcp-meta.json](mcp-meta.json) specifies. The server serves the text inside each fenced block verbatim. Everything outside the blocks is commentary.

## Server instructions

Clients such as Claude Code load these instructions at the start of a session. Claude Code cuts them at 2 KB, so they must stay within 2,048 bytes of UTF-8.

```text
RepoRanger answers questions about this repository from a prebuilt index: symbols, calls and references resolved by the compiler, tests, dependencies, git history, and full-text search. Use it before reading files when the question is structural: who calls X, what breaks if X changes, which tests cover X, where a string appears.

- Start with repo_map for an overview, or with find_symbols and search to get IDs.
- Targets are node IDs or path:line locators, up to 50 per call.
- get_neighbors is one hop. get_impact is transitive: depth 3 by default and 6 at most, ranked and capped.
- Every edge has a resolution level: resolved (a compiler or a structural fact), import-scoped, or name-match (a guess).
- Check _meta on every result. stale means the index lags the working tree: run index_repo. pending above 0 means edges from recently edited files show the last full index.
- Lists page with next_cursor, and responses stay under about 8,000 tokens.
- pack_context builds a token-budgeted bundle of code and evidence for a question.

The usage prompt has the full guide.
```

## Usage prompt

The `usage` prompt returns this text as one user message. `{repo}` is replaced by the prompt's repo argument, or by the default repository's name.

```text
You have RepoRanger's tools for the repository {repo}. They answer from an index of its code, history, and dependencies, which makes them faster and more precise than reading files for structural questions. Read files when you need whole bodies or anything the index doesn't hold.

Which tool answers which question
- What is this repository, and where do things live? repo_map, then get_module on a community or a file.
- Where is something defined or mentioned? find_symbols for names, search for any text.
- What is this symbol? get_symbol: signature, doc comment, snippet, and metrics.
- What calls it, and what does it call? get_neighbors, with direction in or out.
- What could break if it changes? get_impact, upstream. What does it rely on? get_impact downstream, or get_dependencies for packages and modules.
- Which tests cover it? get_tests_for; via_callers adds tests that reach it through callers.
- Where does change concentrate? get_hotspots, then get_history for the commits behind a file or module.
- What do I need to answer a question? pack_context, with targets or the question and a token budget.
- Is the index current and complete? get_index_info.

Targets
Pass node IDs exactly as tools return them; they're opaque. A path:line locator, such as src/Auth/LoginController.cs:42, resolves to the innermost symbol at that line, which helps with stack traces and diffs. One call takes up to 50 targets. A target that fails is listed in errors, and the other targets are still answered.

Trust
Every edge has a resolution level. resolved means a compiler identified the target, or the edge is a structural fact such as containment. import-scoped means the name was matched within the files the source imports. name-match is a repository-wide guess. Use min_resolution when precision matters, and say so when an answer rests on guesses. Every node and edge carries its file and lines; cite them.

Impact
get_impact treats its targets as one change set. Upstream it follows callers and references, and it reaches the callers of an interface member from its implementations. Depth is 3 by default and 6 at most. Results are ordered by depth, then importance, and capped by limit. levels says how many nodes each depth has, and truncated says the traversal stopped early. A widely used symbol can reach a third of the code at depth 3, so narrow with edge_types or min_resolution rather than paging through everything.

Paging and size
List tools return up to limit items, and next_cursor when there are more; pass it back unchanged. Responses stay under about 8,000 tokens and set truncated when they're cut. Narrower filters (path globs, kinds, languages) usually work better than paging.

Freshness
Every result carries _meta: indexed_commit, index_age in seconds, stale, schema_version, state, dirty, refreshed, pending, and changed. Before answering, the server refreshes up to 20 changed files within 2 seconds. A refreshed file has current symbols and text, but its outgoing edges keep the last full resolution until index_repo runs: pending counts such files, and their edges carry pending. When stale is true, more has changed than a refresh covers. Run index_repo, which works in the background, and follow its progress with get_index_info.

Search
search returns two lists. symbols matches words in names, qualified names, signatures, and doc comments, and splits camelCase and snake_case, so user finds GetUserById. text matches any substring of three or more characters, ignoring case, and returns the matching line with context. Narrow with path, languages, kinds, and is_test.
```
