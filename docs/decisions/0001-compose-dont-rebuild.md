# ADR 0001: Compose existing tools; build the fact base and the differentiators

- **Status:** Proposed
- **Date:** 2026-09-18

## Context

The ten planned capabilities span docs, audits, reviews, tests, observability, and backlog. The [landscape research](../research/oss-landscape-2026-09.md) found strong open-source coverage for developer docs, LLM-friendly packaging, security scanning, code review, code indexing, and SBOM and technical-debt analysis. It found nothing purpose-built for business docs, observability recommendations, or findings-to-backlog generation. No single project covers more than about four of the ten capabilities.

## Decision

RepoRanger reuses open-source work where it is strong and permissively licensed, and builds the parts that make it a product.

- **Reuse:** permissively licensed tools that fit behind RepoRanger's own contracts. Examples: the SCIP indexers (precise code structure, [ADR 0011](0011-scip-first-extraction.md)), Repomix (LLM packs), CodeWiki (developer docs), Semgrep CE run as an external tool (SAST), Syft and OSV-Scanner (SBOM and licenses), and Stryker/Stryker.NET (test-suite quality).
- **Reference only:** copyleft or unmaintained projects whose design is worth borrowing but whose code isn't linked. Examples: Kodus (finding-to-issue lifecycle), Qodo Cover (generate → run → keep only passing tests), and the VVAH and Cloudflare audit pipelines.
- **Build:** the repository fact base (Module 1); a findings store with a SARIF-style schema and content-hash IDs (dedupe, suppress, trend); a lens runner with tiered models, per-lens token budgets, and adversarial second-model validation; and renderers for business docs, observability recommendations, and the backlog, with Azure DevOps and Jira write-back.

### How the index decision evolved

The first recommendation was to wrap CodeGraphContext as the graph and MCP layer. The Module 1 design then grew into a repository fact base: the code graph plus history signals, artifact inventories, provenance on every fact, a health report, and a sensitivity policy. None of the code-graph tools reviewed offer that combination, so Module 1 builds its own index. Existing indexers stay useful as references and as possible sources of components. That choice was confirmed on 2026-09-19 as [ADR 0009](0009-build-the-index-in-house.md). A second research pass the same day found the category far more crowded than the first pass showed (see the corrected [research](../research/oss-landscape-2026-09.md)), which led to importing extraction from SCIP instead of writing parsers ([ADR 0011](0011-scip-first-extraction.md)).

## Consequences

- The findings schema becomes the central contract between lenses and renderers.
- Every reused component needs a license check ([ADR 0007](0007-permissive-licensing.md)) and must sit behind a RepoRanger interface so it can be replaced.
- The same discussion proposed a sequence: index and MCP server first; then lenses with deterministic inputs (security, hotspots); then docs; then the three green-field modules; test generation last, as the weakest return. The MVP brief later named Documentation as the first consumer, so module order is an [open decision](../roadmap.md#open-decisions).
- This record stays Proposed until the lens modules are designed and each reuse choice is confirmed. The Module 1 part is decided in [ADR 0009](0009-build-the-index-in-house.md).
