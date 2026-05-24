# Milestones

## v0.10 Adopter Success

**Date:** 2026-05-24
**Stats:**

- Phases: 15-18 (4 phases)
- Plans: 12
- Code change: 30 files, +764/−28 (lib/priv/test); docs: 10 files, +697 (lib+priv now ~11.4k LOC)
- Timeline: 2026-05-23 → 2026-05-24 (~2 days, 98 commits incl. planning)

### Accomplishments

1. Landed the credibility gate: populated hex.pm metadata (`links:` for GitHub/HexDocs/Issues, `:description`, `source_url`, a `docs:` extras block) plus a Release-Please-owned `CHANGELOG.md` and a retroactive `docs/HISTORY.md` covering v0.1–v0.9, with `CHANGELOG*` in the Hex `files:` whitelist.
2. Shipped one-line SLO starter packs — `Parapet.SLO.StarterPack.WebSaaS` (HTTP availability, login journey, Oban job-success) and `DeliverySaaS` (adds Mailglass + Chimeway delivery slices that compile out when the providers are absent) — all low-cardinality with a non-zero denominator guard, riding the existing multi-burn-rate Generator with zero changes.
3. Made the `warning:` runbook annotation render end-to-end (DSL `step/2` → WorkbenchContract projection → Operator UI card); it was previously silently swallowed by Elixir's macro keyword handling.
4. Deepened the four existing runbook templates (`dead_letter`, `callback_delay`, `stalled_executor`, `provider_outage`) and authored three new ones (`retry_storm`, `suppression_drift`, `partial_backlog_drain`) to full RCV depth — precondition, scoped preview, warning, bounded mitigation, post-action verification — all host-owned via the generator's `on_exists: :skip` contract.
5. Authored seven adoption guides — `getting-started` (cold start to first generated alert in <30 min, zero raw PromQL), `troubleshooting` (five predictable obstacles), `slo-authoring-guide` (journey-slicing decision tree + low-traffic guardrails), and per-integration guides for Sigra/Accrue/Rulestead/Threadline — that accurately name the Phase 15–17 surfaces.
6. Introduced a `Parapet.Integration` behaviour (declared on all eight adapters) that makes `Parapet.attach(adapters: […])` uniform and crash-proof, fixing the Rulestead `attach/0` defect so every integration activates from the same line.

### Audit

Milestone audit `passed` (2026-05-24): 11/11 requirements, 4/4 phases, 5/5 integration, 5/5 flows. Nyquist compliant (phases 15–18). First audit returned `tech_debt`; a closure pass the same day resolved the adopter-facing items (slo-reference cross-ref, integration-guide detection wording, Nyquist reconciliation). See `milestones/v0.10-MILESTONE-AUDIT.md`.

### Known Gaps

None blocking. Carried forward: the `release-as: "0.10.0"` pin in `release-please-config.json` is intentionally **retained** until the v0.10.0 release PR merges and tags v0.10.0 (removing it earlier risks a wrong first-version computation); and a non-blocking manual UAT set (30-min cold-start walkthrough, per-integration activation-without-reading-source, AC-03 amber warning-block render in the Operator UI).

---

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

## v0.3 Runbooks & Alert Routing

**Date:** 2026-05-12
**Stats:**

- Phases: 1-4
- Plans: 12
- Total LOC: 6667 (Elixir/EEx)

### Accomplishments

1. Implemented a webhook receiver endpoint for Prometheus Alertmanager, automatically routing "firing" and "resolved" alerts to the durable Ecto Incident lifecycle with intelligent deduplication and correlation.
2. Created a structured `Parapet.Runbook` DSL for defining operator-triggered mitigation steps and attaching them based on SLOs or alert names.
3. Extended the Operator UI to interactively display attached runbooks and execute one-click mitigations with complete `ToolAudit` logging.
4. Built a modular `Parapet.Notifier` system with out-of-the-box Slack (Block Kit) and MS Teams (Adaptive Cards) adapters to broadcast incident state changes and record timeline entries.
5. Added UI capabilities for Operators to explicitly acknowledge incidents and generate comprehensive markdown retrospectives automatically.

### Known Gaps

None. All v0.3 requirements defined and satisfied.

## v0.4 Scoria AI Integration

**Date:** 2026-05-15
**Stats:**

- Phases: 1-4
- Plans: 9
- Total LOC: 7847 (Elixir/EEx)

### Accomplishments

1. Implemented telemetry translation consuming `Scoria.SRE.Telemetry` events and producing Parapet Prometheus metrics and durable Ecto Incidents.
2. Built `Parapet.SLO.ScoriaEval` to define and alert on Eval-Driven SLOs based on Scoria deterministic evaluation scores.
3. Added native tracking of AI Config Changes (`scorer_version`, `baseline_version`, `model`) and visualization in Grafana for SLO error budget correlation.
4. Monitored Scoria MCP tools failure modes (`timeout`, `execution_failed`, `breaker_open`, `access_denied`) as explicit SLIs.
5. Monitored Scoria workflow approval pauses as durable HITL states, triggering alerts on stale requests, and extending Operator UI with deep-links to Scoria's durable evidence.

### Known Gaps

None. All 11/11 requirements defined for v0.4 were satisfied and verified.

## v0.5 Proactive Resilience & Copilot Triage

**Date:** 2026-05-16
**Stats:**

- Phases: 1-3
- Plans: 9
- Total LOC: ~8500 (Elixir/EEx)

### Accomplishments

1. Implemented `Parapet.Probe` for defining and scheduling active synthetic canaries via `NativeScheduler` and `ObanScheduler`.
2. Expanded `Sigra` and `Accrue` integrations to emit explicit login, signup, and checkout SLIs.
3. Built a Parapet MCP server to allow AI agents to safely read incident data and act as triage copilots.
4. Resolved compilation and type warnings across the project, achieving a clean zero-warning compilation state.

### Known Gaps

None. All requirements defined for v0.5 were satisfied and verified.

## v0.6 Change Correlation & Audit Trailing

**Date:** 2026-05-17
**Stats:**

- Phases: 1-3
- Plans: 9
- Total LOC: 8968 (Elixir/EEx)

### Accomplishments

1. Implemented OpenTelemetry trace exemplar extraction from events and process dictionaries, appending `trace_id` to generated Prometheus metrics.
2. Added `trace_id` storage to Ecto `Incident` schemas and dynamically formatted trace links within the Operator UI.
3. Consumed `Rulestead` feature flag toggles via telemetry, creating durable timeline entries and suspect change markers to instantly correlate changes with SLO burn rates.
4. Highlighted recent proximate system changes (like flag toggles) on active incidents in the Operator UI, distinguishing them visually from human actions.
5. Implemented `Parapet.Integrations.Threadline` for compliance sync, mirroring Operator audit actions to Threadline event logs.
6. Added `:threadline_deferred` and `:dual_write` audit modes to satisfy strict compliance constraints (bypassing internal Parapet storage entirely when deferred).

### Known Gaps

None. All v0.6 requirements defined and satisfied. Tests pass locally.

## v0.7 Async & Delivery Reliability

**Date:** 2026-05-18
**Stats:**

- Phases: 4-7
- Plans: 12
- Total LOC: 13401 (Elixir/EEx)

### Accomplishments

1. Established safe telemetry contracts for `Mailglass`, `Chimeway`, and `Rindle` integrations to emit bounded async and delivery events.
2. Implemented out-of-the-box provider-first SLOs for async pipeline health and provider delivery states.
3. Created explicit fault-domain triage enrichment for async and delivery incidents, leveraging durable evidence over UI heuristics.
4. Added safe, host-wired recovery runbook templates for stalled async work (e.g., dead-letter handling, retry workflows).

### Known Gaps

None. All v0.7 requirements defined and satisfied. Tests pass locally.

## v0.8 Deterministic Escalation & Bounded Mitigation

**Date:** 2026-05-19
**Stats:**

- Phases: 1-4
- Plans: 8
- Total LOC: ~13900 (Elixir/EEx)

### Accomplishments

1. Built a durable Oban-backed escalation engine (`Parapet.Escalation.Worker`) that routes incidents to next tiers unless acknowledged or resolved.
2. Implemented system-identity (`:system`) execution for Bounded Runbooks to safely perform auto-mitigations using `Parapet.Operator` API.
3. Created an Ecto-backed `CircuitBreaker` leveraging `ToolAudit` histories to prevent mitigation flap-loops.
4. Updated the LiveView Operator UI to visualize escalation chains and distinctively style system-executed mitigations with manual trigger overrides.

### Known Gaps

None. All v0.8 requirements defined and satisfied. Tests pass locally.

## v0.9 Performance, Scale & DX

**Date:** 2026-05-23
**Stats:**

- Phases: 1-14 (Phases 1-5 core deliverables; Phases 6-14 closure & reconciliation)
- Plans: 36
- Total LOC: ~20,274 (Elixir/EEx, lib+priv+test)
- Timeline: 2026-05-19 → 2026-05-23 (5 days, 88 commits)

### Accomplishments

1. Shipped proactive TSDB cardinality protection: a `mix parapet.doctor cardinality` static analyzer plus a compile-time `Parapet.Metrics.Validator` enforcing a 10-label ceiling per metric, applied across all built-in metrics and adapter SLIs.
2. Delivered database scale & pruning: composite indexes for `Incident`/`TimelineEntry`/`ToolAudit` at >100k rows, a `Parapet.Evidence.Archiver` with resolved-only retention, and a `mix parapet.archive` task plus Oban cron worker that never prunes active `investigating` work.
3. Made the Operator UI responsive under load with bounded queue paging, index-aware Operator queries, and a 50k+ incident benchmark — and repaired the generated resolve flow so the active→resolved lifecycle is true again.
4. Unified the Day-1 experience under `mix parapet.install`, a deterministic Igniter orchestrator that chains spine/prometheus/ui with explicit opt-in extras, backed by severity-aware multi-node `mix parapet.doctor` checks (e.g., Oban uniqueness).
5. Proved multi-node safety with Ecto-backed action claims and circuit breakers under concurrency simulation, plus an environment-conditional peer-node canary that skips cleanly without distributed Erlang.
6. Hardened milestone closure: phases 6-14 backfilled milestone-grade verification surfaces, reconciled planning-artifact drift, tightened archive retention, and added a regression-catching closure-proof chain for the generated operator UI.

### Audit

Milestone audit `passed` (2026-05-23): 12/12 requirements, 12/12 phases, 7/7 integration, 8/8 flows. See `milestones/v0.9-MILESTONE-AUDIT.md`.

### Known Gaps

None blocking. Carried-forward tech debt: family-level requirement IDs in some older summary frontmatter (manual cross-check), non-normalized Nyquist validation frontmatter on Phases 1/2/5/6, a manual fresh-host adoption transcript for Phase 4 (vs. automated bootstrap), a non-blocking EEx `<%# ... %>` deprecation warning in the generated UI proof lane, and cross-milestone phase-directory contamination in `.planning/phases/` pending `/gsd:cleanup`.
