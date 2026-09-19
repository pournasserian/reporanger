# ADR 0002: Bring your own key, with model roles

- **Status:** Accepted
- **Date:** 2026-09-18

## Context

RepoRanger's users will have different model providers, budgets, and data rules. The project should not lock anyone into one provider or one local runtime. Users decide which models run which work: in configuration first, and later in an admin UI. Keeping code strictly on-premises is not a requirement.

## Decision

- **BYOK from day one.** Users configure their own providers and keys. RepoRanger ships no hosted model.
- **Model roles, not model names.** Work is assigned to roles: `extract`, `triage`, `synthesize`, `verify`, and `embed`. Configuration maps each role to a provider and model. Lenses and features ask for a role, never for a specific model.
- **Any OpenAI-compatible endpoint is a provider.** Local runtimes such as Ollama work without special treatment, and none is privileged.
- **Metered spend.** Every LLM call is logged with its token cost per run, and summary generation is capped by a user-configured budget. There is no fixed per-run cost target.
- **Module 1 P0 makes no LLM calls** (decided in the review of 2026-09-19), so the configuration file arrives with summaries in P1. **P2:** an admin UI for model roles.

## Consequences

- Each implementation stack needs a provider abstraction that supports the roles.
- The `verify` role makes adversarial validation with a different model a configuration choice rather than a code change.
- The token and cost log ships with the first LLM feature, in P1.
- Module 1 uses `extract` for symbol and file summaries and `synthesize` for module and repo summaries (decided 2026-09-19). The remaining role semantics are finalized in milestone M0 (see the [design notes](../modules/01-ingest-and-index/design-notes.md#model-roles-p1)).
