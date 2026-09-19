# Contributing to RepoRanger

Thanks for your interest. RepoRanger is in the **design phase**: the repository holds documentation only, so the most useful contributions right now are feedback on the design.

## How to help now

- **Question or challenge a document.** Open an issue that names the document and section, and say what you would change and why.
- **Propose a change.** For small fixes (typos, broken links, unclear wording), open a pull request directly. For changes to scope or features, open an issue first.
- **Propose a decision.** Add a record under [docs/decisions/](docs/decisions/README.md) with the status `Proposed`, following the template there, and open a pull request.

## Documentation conventions

- Markdown, one topic per file. Link to other docs instead of repeating them.
- Start each document with a one-line status (Draft, Proposed, or Accepted) and a last-updated date.
- Lead with the point and keep sentences short. Use tables for comparisons and Mermaid for diagrams.
- Use the terms in the [glossary](docs/glossary.md), and add new terms there.
- Never edit a decision away. To change one, add a new record that supersedes it.
- Write the product name as RepoRanger in prose, and as `reporanger` for the repository, the CLI, and packages.

## Code contributions

There is no code yet. How code will be written is already decided: spec-driven per milestone, contract-first per interface, test-driven per task, with an adversarial review before a task is done. See [docs/development-workflow.md](docs/development-workflow.md); `CLAUDE.md` holds the conventions Claude Code sessions follow. Build, test, and style commands are added when M1 starts (see the [roadmap](docs/roadmap.md)).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
