# Phase 1: Telemetry Foundation & Safety Rails - Context

**Gathered:** 2026-05-09
**Status:** Ready for planning

<domain>
## Phase Boundary

The library's core safety guarantees are in place — adopters can install Parapet and trust that their metrics will be correct and secure from day one. This includes the core supervisor, label policy, optional dependency seams, the install generator, and the CI setup.

</domain>

<decisions>
## Implementation Decisions

### Project Initialization & Setup
- **D-01:** The project will be initialized as a supervised library (`mix new parapet --sup`). This establishes the explicit OTP application boundary required to manage telemetry lifecycle and cache states.
- **D-02:** The `files:` whitelist in `mix.exs` will strictly include only standard runtime and doc files, keeping the package free of planning and prompt artifacts.

### CI & Release Engineering
- **D-03:** The full "Rulestead-style" CI pipeline (GitHub Actions, Release Please, Conventional Commits) is implemented immediately.
- **D-04:** Strict gates: `mix format`, `credo --strict`, `dialyzer`, and `mix verify.public_api` must pass from day 1 to enforce documentation and typing.

### Installer Approach (`mix parapet.install`)
- **D-05:** The installer will use `Igniter` (if applicable/stable) or robust AST-aware patching to append `Parapet.Plug.Metrics` to the host app's Endpoint and configure `Parapet.Instrumenter`.
- **D-06:** The installer builds the complete scaffolding logic in Phase 1, even though the HTTP metrics telemetry implementations themselves ship in Phase 2. This de-risks DX up front.

### Telemetry & Safety Rails
- **D-07:** Label policy enforcement must occur as early as possible. We will design macros or compile-time checks to reject known high-cardinality labels (like `user_id` or `path`).
- **D-08:** Handlers must never crash the host process. We will wrap handler logic in resilient exception boundaries (`try/rescue` inside telemetry handlers) and log errors instead of bringing down the application.
- **D-09:** Optional dependencies (`:oban`, `:sigra`) will use `if Code.ensure_loaded?` checks.

### Claude's Discretion
- The exact internal module structure under `Parapet.Internal` is left to Claude's discretion.
- The use of `Igniter` vs regex/Sourceror for the installer is up to the planner based on what provides the most idiomatic and stable DX.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### OSS & Project DNA
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — Rulestead/sibling lib release/CI discipline.
- `prompts/prior-art/rulestead-release-engineering-and-ci.md` — CI/CD, Hex publishing, and verification patterns.
- `prompts/prior-art/rulestead-telemetry-observability-and-audit.md` — Telemetry vs. audit, context redaction, and event schema design.
- `prompts/elixir-telemetry-space-deep-research.md` — Ecosystem state, Prometheus integration, and DX best practices.
- `prompts/prior-art/chimeway-host-app-integration-seam.md` — Boundary principles between host and library.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- N/A (Greenfield initialization)

### Established Patterns
- We will inherit the `mix verify.*` pattern from the Rulestead/sibling libs to assert public API documentation and package hygiene.
- `telemetry.span/3` will be used for execution tracing within Parapet operations.

</code_context>

<specifics>
## Specific Ideas

- The user specifically requested a "deeply thought-out, one-shot perfect set of recommendations" based on the sibling library DNA, emphasizing great DX, strict boundaries, and "host-owned" artifacts.

</specifics>

<deferred>
## Deferred Ideas

- HTTP, Ecto, Oban specific metric hookups (Phase 2).
- SLO definition and alerting rules (Phase 3).
- Grafana dashboard generation (Phase 4).

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-05-09*
