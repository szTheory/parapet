# Parapet Milestone History

This document records the development milestones for Parapet v0.1–v0.9.
These are planning tranches, not Hex release versions — the package was not
published to hex.pm during this period.

For the changelog of published Hex releases (v0.10+), see [CHANGELOG.md](../CHANGELOG.md).

---

## v0.9 — Performance, Scale & DX (2026-05-23)

- Shipped proactive TSDB cardinality protection: a `mix parapet.doctor cardinality` static
  analyzer plus a compile-time Parapet.Metrics.Validator enforcing a 10-label ceiling per metric,
  applied across all built-in metrics and adapter SLIs.
- Delivered database scale and pruning: composite indexes for Incident, TimelineEntry, and
  ToolAudit at over 100k rows, a Parapet.Evidence.Archiver with resolved-only retention, and
  a `mix parapet.archive` task plus Oban cron worker that never prunes active investigating work.
- Made the Operator UI responsive under load with bounded queue paging, index-aware Operator
  queries, and a 50k+ incident benchmark — and repaired the generated resolve flow so the
  active-to-resolved lifecycle is true again.
- Unified the Day-1 experience under `mix parapet.install`, a deterministic Igniter orchestrator
  that chains spine/prometheus/ui with explicit opt-in extras, backed by severity-aware multi-node
  `mix parapet.doctor` checks (for example, Oban uniqueness).
- Proved multi-node safety with Ecto-backed action claims and circuit breakers under concurrency
  simulation, plus an environment-conditional peer-node canary that skips cleanly without
  distributed Erlang.
- Hardened milestone closure: phases 6–14 backfilled milestone-grade verification surfaces,
  reconciled planning-artifact drift, tightened archive retention, and added a
  regression-catching closure-proof chain for the generated operator UI.

**Stats:** ~20,274 LOC (Elixir/EEx, lib+priv+test) · Phases 1–14 (5 core, 9 closure) · 36 plans · 88 commits · 2026-05-19 → 2026-05-23

---

## v0.8 — Deterministic Escalation & Bounded Mitigation (2026-05-19)

- Built a durable Oban-backed escalation engine (Parapet.Escalation.Worker) that routes incidents
  to next tiers unless acknowledged or resolved.
- Implemented system-identity execution for Bounded Runbooks to safely perform auto-mitigations
  using the Parapet.Operator API, logging all actions under the `:system` URN identity.
- Created an Ecto-backed circuit breaker leveraging ToolAudit histories to prevent mitigation
  flap-loops: once a mitigation has run N times, the breaker trips and escalates instead.
- Updated the LiveView Operator UI to visualize escalation chains and distinctively style
  system-executed mitigations with manual trigger overrides for operator control.

**Stats:** ~13,900 LOC (Elixir/EEx) · Phases 1–4 · 8 plans · 2026-05-19

---

## v0.7 — Async & Delivery Reliability (2026-05-18)

- Established safe telemetry contracts for Mailglass, Chimeway, and Rindle integrations to emit
  bounded async and delivery events using normalized event semantics for diverse external providers.
- Implemented out-of-the-box provider-first SLOs for async pipeline health and provider delivery
  states, including multi-burn-rate PromQL alerts.
- Created explicit fault-domain triage enrichment for async and delivery incidents, leveraging
  durable evidence — triage snapshot chronology — over UI-derived heuristics.
- Added safe, host-wired recovery runbook templates for stalled async work, covering dead-letter
  handling, provider outage recovery, stalled job cleanup, and callback delay flows.

**Stats:** ~13,401 LOC (Elixir/EEx) · Phases 4–7 · 12 plans · 2026-05-18

---

## v0.6 — Change Correlation & Audit Trailing (2026-05-17)

- Implemented OpenTelemetry trace exemplar extraction from events and process dictionaries,
  appending trace identifiers to generated Prometheus metrics.
- Added trace identifier storage to Ecto Incident schemas and dynamically formatted trace links
  within the Operator UI for one-click navigation to external trace backends.
- Consumed Rulestead feature flag toggles via telemetry, creating durable timeline entries and
  suspect change markers to instantly correlate feature flag changes with SLO burn rates.
- Highlighted recent proximate system changes (like flag toggles) on active incidents in the
  Operator UI, distinguishing them visually from human actions.
- Implemented Parapet.Integrations.Threadline for compliance sync, mirroring Operator audit
  actions to Threadline event logs.
- Added dual audit modes (`:threadline_deferred` and `:dual_write`) to satisfy strict compliance
  constraints, including bypassing internal Parapet storage entirely when deferred.

**Stats:** 8,968 LOC (Elixir/EEx) · Phases 1–3 · 9 plans · 2026-05-17

---

## v0.5 — Proactive Resilience & Copilot Triage (2026-05-16)

- Implemented Parapet.Probe for defining and scheduling active synthetic canaries via
  NativeScheduler and ObanScheduler, enabling proactive health detection before alerts fire.
- Expanded Sigra and Accrue integrations to emit explicit login, signup, and checkout SLIs for
  business-critical journey monitoring.
- Built a Parapet MCP server to allow AI agents to safely read incident data and act as triage
  copilots, providing structured access without write permissions.
- Resolved compilation and type warnings across the project, achieving a clean zero-warning
  compilation state.

**Stats:** ~8,500 LOC (Elixir/EEx) · Phases 1–3 · 9 plans · 2026-05-16

---

## v0.4 — Scoria AI Integration (2026-05-15)

- Implemented telemetry translation consuming Scoria.SRE.Telemetry events and producing Parapet
  Prometheus metrics and durable Ecto Incidents for AI infrastructure observability.
- Built Parapet.SLO.ScoriaEval to define and alert on Eval-Driven SLOs based on Scoria
  deterministic evaluation scores, with Grafana visualization for SLO error budget correlation.
- Added native tracking of AI Config Changes (scorer_version, baseline_version, model) to
  correlate configuration drift with SLO degradation.
- Monitored Scoria MCP tool failure modes (timeout, execution_failed, breaker_open, access_denied)
  as explicit SLIs using bounded atoms to protect Ecto from high-volume telemetry.
- Monitored Scoria workflow approval pauses as durable human-in-the-loop states, triggering alerts
  on stale requests, and extended the Operator UI with deep-links to Scoria's durable evidence.

**Stats:** 7,847 LOC (Elixir/EEx) · Phases 1–4 · 9 plans · 2026-05-15

---

## v0.3 — Runbooks & Alert Routing (2026-05-12)

- Implemented a webhook receiver endpoint for Prometheus Alertmanager, automatically routing
  "firing" and "resolved" alerts to the durable Ecto Incident lifecycle with intelligent
  deduplication and correlation by alert name and labels.
- Created a structured Parapet.Runbook DSL for defining operator-triggered mitigation steps and
  attaching them based on SLOs or alert names.
- Extended the Operator UI to interactively display attached runbooks and execute one-click
  mitigations with complete ToolAudit logging.
- Built a modular Parapet.Notifier system with out-of-the-box Slack (Block Kit) and Microsoft
  Teams (Adaptive Cards) adapters to broadcast incident state changes and record timeline entries.
- Added UI capabilities for operators to explicitly acknowledge incidents and generate comprehensive
  Markdown retrospectives automatically.

**Stats:** 6,667 LOC (Elixir/EEx) · Phases 1–4 · 12 plans · 2026-05-12

---

## v0.2 — Durable Spine and Operator UI (2026-05-11)

- Implemented the Parapet.Evidence context with Incident, TimelineEntry, and ToolAudit Ecto
  schemas for durable SRE tracking, separating ephemeral telemetry from low-volume Ecto data.
- Created `mix parapet.gen.spine` generator to scaffold evidence migrations into host applications
  safely separated from high-volume telemetry.
- Defined the Operator API with transactional audited commands and a WorkbenchContract for safe
  UI derivations.
- Created `mix parapet.gen.ui` to generate an isolated, secure, and visually responsive Phoenix
  LiveView Operator Workbench inside the host app.
- Automated structural UI tests to guarantee responsive mobile and desktop layout fidelity without
  relying on human QA or full browser end-to-end tests.
- Implemented optional integration adapters for Mailglass, Chimeway, Accrue, Rindle, Threadline,
  and Rulestead leveraging a new capability registry, with all adapters compiling out cleanly when
  their sibling libraries are absent.

**Stats:** 3,164 LOC (Elixir/EEx) · Phases 1–3 · 11 plans · 2026-05-11

---

## v0.1 — Trustworthy Spine (2026-05-10)

- Established the foundational Parapet telemetry contract, supervisor, and install generator,
  defining a documented telemetry surface treated as a public API with semver guarantees.
- Built core metrics instrumentation for HTTP, Ecto, and Oban safely via a robust API enforcing
  low-cardinality by default with explicit label contracts.
- Created an SLO DSL converting standard Elixir definitions to fully functional Prometheus
  recording and alerting rules.
- Delivered a seamless Day-1 experience with `mix parapet.doctor` health checks and Grafana
  dashboard generation.

**Stats:** 1,992 LOC (Elixir) · Phases 1–4 · 15 plans · 2026-05-10
