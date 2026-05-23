# Parapet

## What This Is

Parapet is an open-source Phoenix reliability layer for Elixir SaaS teams: an opinionated SRE substrate that turns existing telemetry into safe metrics, user-journey SLOs, deploy correlation, incident evidence, runbooks, doctor checks, and operator-grade diagnostics. It composes Phoenix, Ecto, Oban, OpenTelemetry, Prometheus, and Grafana into a coherent reliability story without replacing any of them. The target adopter is a Phoenix SaaS team that has good tools but no paved road connecting them.

## Core Value

A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## Current State

**Shipped:** v0.9 Performance, Scale & DX (2026-05-23) — TSDB cardinality protection, database scale & pruning, responsive Operator UI under 50k+ incidents, a unified `mix parapet.install` Day-1 path, and Ecto-backed multi-node safety. Milestone audit `passed` (12/12 requirements). See `.planning/MILESTONES.md`.

**Next:** Planning the next milestone via `/gsd:new-milestone` (fresh requirements + roadmap).

## Requirements

### Validated

- ✓ Single `parapet` Hex package with a narrow, explicit public surface and `files:` whitelist — v0.1
- ✓ Documented telemetry contract treated as public API — redaction-safe, low-cardinality by default — v0.1
- ✓ HTTP/API request health SLI/SLO slice — error rate, latency, availability per route group — v0.1
- ✓ Oban/job health SLI/SLO slice — failure rate, throughput, latency per queue and worker — v0.1
- ✓ Login journey as the first business-critical SLO — auth success rate via `sigra` integration — v0.1
- ✓ Deploy/change markers — correlated with SLO windows and error spikes — v0.1
- ✓ Grafana dashboard and Prometheus alerting rule artifacts generated or documented as sane defaults — v0.1
- ✓ Minimal `mix parapet.doctor` health check surface for adopter confidence — v0.1
- ✓ Day-1 install guide and README that covers configuration through first alert — v0.1
- ✓ System provides Ecto schemas for Incidents with a state machine (open, investigating, resolved) — v0.2
- ✓ System provides Ecto schemas for Timeline Entries linked to Incidents to durably track alerts, notes, and actions — v0.2
- ✓ System provides Ecto schemas for Tool Audits to securely log AI and human MCP tool calls — v0.2
- ✓ System enforces a clear boundary preventing raw high-volume telemetry from entering Ecto — v0.2
- ✓ System provides a Phoenix LiveView SRE dashboard to manage incidents and timelines — v0.2
- ✓ System provides a secure UI surface to execute and audit application mutations (e.g., toggling feature flags) — v0.2
- ✓ System UI integrates external visualization links (e.g., Grafana) rather than rebuilding charting in LiveView — v0.2
- ✓ System provides generators to secure the LiveView UI behind host application authentication — v0.2
- ✓ Optional Rulestead integration to track feature flag changes and enable flag-toggling mitigations — v0.2
- ✓ Optional Mailglass and Chimeway integrations for deliverability SLIs — v0.2
- ✓ Optional Accrue (billing) and Rindle (media processing) integrations for business-specific journey health — v0.2
- ✓ Strict adherence to the "compile out cleanly" constraint for all sibling libraries — v0.2
- ✓ Conceptual integration with Threadline for durable audit history interoperability — v0.2
- ✓ System provides a webhook receiver endpoint compatible with Prometheus Alertmanager — v0.3
- ✓ System automatically converts incoming Alertmanager "firing" alerts into durable Ecto Incidents — v0.3
- ✓ System automatically resolves or updates Ecto Incidents when Alertmanager sends a "resolved" webhook — v0.3
- ✓ System correlates incoming alerts to existing open incidents if they share the same alert name and labels — v0.3
- ✓ System provides a DSL (`Parapet.Runbook`) to define structured runbooks with explicit steps — v0.3
- ✓ System allows mapping specific runbooks to specific SLOs or alert names — v0.3
- ✓ System Operator UI displays the attached runbook interactively on the Incident detail page — v0.3
- ✓ System provides a mechanism for "one-click mitigations" (e.g., executing a server-side callback function) — v0.3
- ✓ System provides a modular notification behavior (`Parapet.Notifier`) for broadcasting incident state changes — v0.3
- ✓ System includes out-of-the-box Slack and Microsoft Teams adapters for rich notifications — v0.3
- ✓ System durably records all dispatched notifications as Timeline Entries on the incident — v0.3
- ✓ System allows operators to explicitly acknowledge incidents via the Operator UI, tracking the action securely — v0.3
- ✓ System automatically generates a Markdown retrospective for resolved incidents based on the evidence timeline — v0.3
- ✓ System achieves a 100% green test suite with zero deferred testing blockers for v0.3 — v0.3
- ✓ System consumes Scoria's `Scoria.SRE.Telemetry` events and translates them into Parapet Prometheus metrics and durable Ecto Incidents — v0.4
- ✓ System provides scoria_llm_token_count_total, scoria_llm_cost_usd, and scoria_llm_time_to_first_token_ms in Grafana out-of-the-box using the SRE telemetry layer — v0.4
- ✓ System enforces a strict label policy that filters high-cardinality refs (like `trace_id`) from metrics labels, strictly splitting labels and refs — v0.4
- ✓ System expands Parapet.SLO to include Parapet.SLO.ScoriaEval for defining objectives based on Scoria deterministic evaluation scores — v0.4
- ✓ System tracks and alerts on Eval-Driven SLOs — v0.4
- ✓ System surfaces AI Config Changes (`scorer_version`, `baseline_version`, `model`) natively from SRE telemetry — v0.4
- ✓ System visualizes AI Config Changes in Grafana to correlate with SLO error budgets — v0.4
- ✓ System tracks explicit failure modes (`timeout`, `execution_failed`, `breaker_open`, `access_denied`) for Scoria MCP tools as SLIs — v0.4
- ✓ System monitors Scoria workflow approval pauses as durable HITL states, not generic queues — v0.4
- ✓ System can trigger alerts on stale or expiring workflow approval requests — v0.4
- ✓ System extends the LiveView Operator UI to deep-link into Scoria's durable evidence and approval UI — v0.4
- ✓ System expands `Chimeway` integration with out-of-the-box SLIs for notification deliverability, provider failures, and backlog drift — v0.7
- ✓ System expands `Mailglass` integration with out-of-the-box SLIs for email deliverability, suppression anomalies, and provider health — v0.7
- ✓ System expands `Rindle` integration with out-of-the-box SLIs for long-running media jobs, webhook delays, and async funnel health — v0.7
- ✓ System surfaces async and delivery incidents in the Operator UI with enough context to distinguish provider drift from internal queue backlog — v0.7
- ✓ System provides built-in runbook templates for stalled async work, including dead-letter handling and safe retry flows — v0.7
- ✓ System provides a `Parapet.Escalation.Policy` behavior and Oban workers for durable severity-based routing — v0.8
- ✓ System automatically cancels or gracefully short-circuits scheduled escalations if the incident is acknowledged or resolved — v0.8
- ✓ System extends `Parapet.Runbook` DSL to support `auto_execute_on: "alert_name"` for bounded mitigations — v0.8
- ✓ System safely executes runbook steps under a `:system` identity and durably logs `ToolAudit` and `TimelineEntry` records — v0.8
- ✓ System implements Ecto-backed circuit breakers querying `ToolAudit` to prevent flap-loop mitigations and escalate instead — v0.8
- ✓ System Operator UI displays the active escalation chain and highlights "System-Executed" mitigations distinctly from human-executed ones — v0.8
- ✓ System Operator UI provides manual controls to trigger next escalations — v0.8
- ✓ System provides a `mix parapet.doctor cardinality` sub-command to statically analyze metrics configurations and flag unsafe label patterns — v0.9
- ✓ System strictly limits the number of labels per metric at compile-time to prevent accidental TSDB explosion — v0.9 (max 10 labels/metric)
- ✓ System provides optimized Ecto migrations to add composite indexes to `Incident`, `TimelineEntry`, and `ToolAudit` for fast querying at >100k rows — v0.9
- ✓ System provides a `Parapet.Evidence.Archiver` module and `mix parapet.archive` task to safely soft-delete or export resolved incidents older than a configurable window — v0.9 (resolved-only retention; active work never pruned)
- ✓ Operator UI Incident list utilizes efficient pagination or cursor-based scrolling to prevent large payload rendering issues — v0.9 (bounded queue paging, 50k+ benchmark)
- ✓ System provides `mix parapet.install` as a unified, interactive starting point that sequentially runs necessary sub-generators — v0.9
- ✓ System's `mix parapet.doctor` checks for correct multi-node configuration (e.g., verifying Oban uniqueness settings for escalations) — v0.9
- ✓ System test suite includes multi-node or concurrency simulation tests verifying that Ecto-backed circuit breakers prevent race conditions — v0.9 (DB-backed contention proof; environment-conditional peer canary)

### Active

<!-- Empty after v0.9 completion. Next milestone requirements defined via /gsd:new-milestone. -->

(None — defining next milestone via `/gsd:new-milestone`)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Hosted observability SaaS — Parapet is host-owned infrastructure, not a vendor product
- APM backend, log database, or trace store — Parapet composes existing systems; it does not replace them
- Replacement for Phoenix Telemetry, OpenTelemetry, LiveDashboard, or vendor SDKs — composing these is the point
- Generic cross-language platform — Elixir/Phoenix ecosystem-native first; cross-language is a different product
- Unbounded autonomous incident-response agent — evidence-first tooling, not AI autopilot

## Context

Shipped v0.2 with a focus on Durable Evidence, LiveView Operator UI, and ecosystem integrations.
The implementation separated ephemeral telemetry from durable low-volume Ecto schema data for incident timelines. A Phoenix LiveView SRE dashboard was generated to provide an operator workbench.
Shipped v0.3 extending capabilities with Alert Routing, Runbooks, and Notifications via Slack/Teams.
Shipped v0.4 adding complete AI observability integration for Scoria (Eval-Driven SLOs, deploy correlation, HITL workflow monitoring).
Shipped v0.5 adding Synthetic Probes, deepened Accrue/Sigra integrations, and a read-only MCP server.
Shipped v0.6 adding trace exemplars, Rulestead change correlation, and Threadline compliance sync.
Shipped v0.7 adding Async & Delivery Reliability, including Chimeway, Mailglass, Rindle SLIs, fault-domain triage enrichment, and host-owned recovery runbooks.
Shipped v0.8 adding Deterministic Escalation & Bounded Mitigation, proving Parapet can take safe action using Oban policies and circuit breakers without relying on autonomous AI agents.
Shipped v0.9 adding Performance, Scale & DX: proactive TSDB cardinality protection, database scale & pruning (resolved-only archiver), a responsive Operator UI proven against 50k+ incidents, a unified `mix parapet.install` Day-1 path, and Ecto-backed multi-node safety. Codebase now ~20,274 LOC (Elixir/EEx, lib+priv+test). The milestone took 14 phases — 5 core deliverables plus 9 closure/reconciliation phases that hardened the verification surfaces after the first audit returned `gaps_found`.

## Constraints

- **Tech stack**: Elixir/Phoenix only — ecosystem-native is a hard constraint, not a preference
- **Package boundary**: Single `parapet` Hex package for v0.1/v0.2
- **Install model**: Generator for host-owned scaffolding, library config for runtime behavior — generated files must remain inspectable and modifiable by the adopter
- **Metrics safety**: Low-cardinality by default, explicit label contracts, redaction-safe metadata — violations of this are bugs, not configuration options
- **Telemetry as API**: Documented telemetry events are a public API surface with semver guarantees — treat breakage the same as a function signature change
- **Optional dependencies**: All integration deps (sigra, oban, etc.) must compile out cleanly when absent — no hard runtime coupling
- **OSS discipline**: Conventional Commits + Release Please, stable CI job ids, `mix verify.*` proof surfaces, `files:` whitelist on Hex publish

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Dynamic Repo lookup via `Application.get_env` | Decouples library from specific host database | ✓ Good |
| Ecto schema changesets tested purely without DB | Ensures decoupling from specific host application databases | ✓ Good |
| Strict boundary between telemetry and Ecto | Prevents Ecto from being used for raw high-volume telemetry | ✓ Good |
| Sibling ecosystem integrations as optional adapters | Adheres to "compile out cleanly" constraint using `Code.ensure_loaded?` | ✓ Good |
| AI/MCP tool calls must be audited | Requires `Parapet.Ecto.ToolAudit` for app mutations | ✓ Good |
| Static analysis of doctor checks | Prevents global compilation side-effects by not dynamically injecting router modules in tests | ✓ Good |
| Automated structural UI layout verification | Verifies responsive tailwind layout logic via static file testing instead of full browser E2E to keep dependency footprint light and fast | ✓ Good |
| Migrate to `Provider` behaviour for SLO Registry | Guarantees compile-time validation and GitOps auditability | ✓ Good |
| Strict cardinality control on Scoria metrics | Aggressively strips high-cardinality data to prevent TSDB bloat | ✓ Good |
| Generate multi-burn-rate PromQL alerts | Adopts Google SRE methodology to prevent false positives on low-traffic | ✓ Good |
| Write AI Config Changes to Ecto as `Incident` | Enables direct querying without round-trips to external TSDB | ✓ Good |
| Map MCP tool failure modes to bounded atoms | Protects Ecto from high-volume telemetry | ✓ Good |
| Parapet observes Scoria native state | Avoids duplicating state or polling | ✓ Good |
| Dual-Track Telemetry for workflow pauses | Prometheus for systemic alerting, Ecto for 100% reliable deep links | ✓ Good |
| Configurable MFA for UI URL resolving | Decouples Parapet from Scoria's routing layer | ✓ Good |
| Dual-track Async/Delivery telemetry | Provides normalized event semantics for diverse external providers | ✓ Good |
| Host-owned runbook modules | Promotes safe, inspectable, and version-controlled mitigation workflows over opaque DSLs | ✓ Good |
| Triage snapshot chronology | Elevates evidence-backed classification above ad hoc UI derivation | ✓ Good |
| Async Runbook auto-execution | Prevents alert ingestion blocking by triggering `Parapet.Automation.Executor` via Oban | ✓ Good |
| Opt-in Auto-execution | Strictly requires `auto_execute: true` in `step/2` macro DSL for bounded safety | ✓ Good |
| Strict URN system identity | Logs `system:automation:executor` in audits/timelines for clear Operator UI styling | ✓ Good |
| Compile-time label ceiling on metrics | Makes TSDB cardinality protection unbypassable (max 10 labels/metric via `Parapet.Metrics.Validator`) rather than a documented guideline | ✓ Good |
| Static cardinality analyzer (`mix parapet.doctor cardinality`) | Flags dynamic/unsafe label patterns before they reach the TSDB | ✓ Good |
| Built-in archiver over cold-storage engine | `mix parapet.archive` + Oban cron prunes resolved evidence without inventing new infrastructure | ✓ Good |
| Resolved-only archive retention contract | Active `investigating` work is never pruned — closes a data-loss footgun | ✓ Good |
| Unified `mix parapet.install` Igniter orchestrator | Deterministic Day-1 path chaining spine/prometheus/ui with explicit opt-in extras | ✓ Good |
| Ecto-backed action claims + circuit breakers for multi-node safety | DB-level atomic checks prevent cross-node race conditions on auto-mitigation | ✓ Good |
| Environment-conditional peer-node canary | Skips cleanly without distributed Erlang instead of failing hard with `:nodistribution` | ✓ Good |
| Closure phases as first-class (Phases 6-14) | Audit-surfaced gaps get their own rerunnable proof artifacts instead of silent patches | ✓ Good |
| Exclude `Parapet.TestSupport.*` from public-API doc gate | Test-support modules under the project namespace no longer halt the suite | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-23 after v0.9 milestone completion*
