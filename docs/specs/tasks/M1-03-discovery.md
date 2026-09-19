# M1-03: Discovery, content hashes, and C# projects

**Status:** Proposed · **Last updated:** 2026-09-19

- **Goal:** Walk a repository, decide what is indexed and what is skipped and why, hash every file the way git would, and find the C# projects.
- **Depends on:** M1-02.
- **Spec references:** [config.md](../config.md), section 5, for the skip reasons and their defaults; [index-schema.sql](../index-schema.sql) for `content_hash`, `extraction`, `skip_reason`, `dirty`, and the file and project node shapes; [plugin-interface.md](../plugin-interface.md), section 7.1, for project detection patterns.
- **Files and interfaces:**
  - `src/RepoRanger.Core/Discovery/`: `Walker` (honours `.gitignore` through LibGit2Sharp, never enters `.git`), `Classifier` (language by extension using Language Server Protocol identifiers, and every skip reason in config.md section 5), `ContentHash` (the git blob ID: read from the index for unchanged tracked files, otherwise hash the content after end-of-line normalization), `ProjectDetector` (C#: `*.csproj`, and solutions for grouping).
  - Output: a file manifest with path, language, extraction status, skip reason, content hash, dirty flag, size, and line counts.
- **Out of scope:** reading file content beyond what classification and hashing need; any extraction; TypeScript and Python projects, which arrive in M3.
- **Tests first:**
  - A temporary repository exercises every skip reason in config.md section 5, one file each.
  - `.gitignore` is honoured, including a nested one, and untracked-but-not-ignored files are discovered and marked dirty.
  - The content hash of a file equals `git hash-object` for the same file, and a CRLF and an LF checkout of the same commit give the same hash.
  - A file whose content differs from HEAD is dirty; an unchanged one is not.
  - Include and exclude globs from configuration narrow the walk, and their skip reason is `excluded`.
  - C# project detection finds every `*.csproj` and maps files to the nearest project.
- **Verification step:** `dotnet run --project src/RepoRanger.Cli -- discover .` over this repository prints the file count by extraction status and skip reason, and a test asserts those counts for the temporary repository.
- **Done when:** the verification step passes, the tests are committed, and the review has no open correctness findings.
