# Milestones

## v0.1 Trustworthy Spine

**Date:** 2026-05-10
**Stats:**
- Phases: 1-4
- Plans: 15
- Total LOC: 1992 (Elixir)

### Accomplishments
1. Established the foundational `Parapet` telemetry contract, supervisor, and install generator.
2. Built core metrics instrumentation for HTTP, Ecto, and Oban safely via robust API.
3. Created an SLO DSL converting standard Elixir definitions to fully functional Prometheus recording/alerting rules.
4. Delivered a seamless day-1 DX with `mix parapet.doctor` and Grafana dashboard generation.

### Known Gaps
None. All 60/60 requirements defined for v0.1 were satisfied and comprehensively tested.

## v0.2 Durable Spine and Operator UI

**Date:** 2026-05-11
**Stats:**
- Phases: 1-3
- Plans: 11
- Total LOC: 3164 (Elixir/EEx)

### Accomplishments
1. Implemented `Parapet.Evidence` context with `Incident`, `TimelineEntry`, and `ToolAudit` Ecto schemas for durable SRE tracking.
2. Created `mix parapet.gen.spine` generator to scaffold evidence migrations into host applications safely separated from high-volume telemetry.
3. Defined the Operator API with transactional audited commands and a `WorkbenchContract` for safe UI derivations.
4. Created `mix parapet.gen.ui` to generate an isolated, secure, and visually responsive Phoenix LiveView Operator Workbench inside the host app.
5. Automated structural UI tests to guarantee responsive mobile and desktop layout fidelity without relying on human QA.
6. Implemented optional integration adapters for `Mailglass`, `Chimeway`, `Accrue`, `Rindle`, `Threadline`, and `Rulestead` leveraging a new capability registry.

### Known Gaps
None. All v0.2 requirements defined and satisfied.
