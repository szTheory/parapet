# Parapet

## What This Is

Parapet is an open-source Phoenix reliability layer for Elixir SaaS teams: an opinionated SRE substrate that turns existing telemetry into safe metrics, user-journey SLOs, deploy correlation, incident evidence, runbooks, doctor checks, and operator-grade diagnostics. It composes Phoenix, Ecto, Oban, OpenTelemetry, Prometheus, and Grafana into a coherent reliability story without replacing any of them. The target adopter is a Phoenix SaaS team that has good tools but no paved road connecting them.

## Core Value

A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## Current State

**Shipped:** v1.0 Stable Release (2026-05-26) — froze the public API + telemetry contract under documented stability tiers and a deprecation policy, completed governance/docs trust surfaces, shipped a runnable demo app as a CI contract test, hardened CI into release-quality lanes, automated Hex publishing from Release Please, and cut the live `v1.0.0` release with Hex + HexDocs resolution and post-cut cleanup on `main`. `main` now returns to steady-state release config with no one-off `release-as` pin. See `.planning/ROADMAP.md` and `docs/release-policy.md`.

**Previously shipped:** v0.10 Adopter Success (2026-05-24) — closed the gap between "feature-complete" and "adoptable by a stranger" without expanding feature surface: populated hex.pm metadata + `links:` and a Release-Please-owned `CHANGELOG.md`/retroactive `docs/HISTORY.md`; one-line `Parapet.SLO.StarterPack.WebSaaS`/`DeliverySaaS` packs (low-cardinality, low-traffic-safe, zero Generator changes); an end-to-end `warning:` runbook surface plus four deepened and three new preview-first runbook templates; and seven adoption guides (getting-started <30 min, troubleshooting, slo-authoring, four per-integration) backed by a `Parapet.Integration` behaviour that makes `Parapet.attach/1` uniform and crash-proof. Milestone audit `passed` (11/11 requirements, 4/4 phases, 5/5 integration, 5/5 flows; Nyquist compliant). See `.planning/MILESTONES.md`.

**Next:** Quiet stable-line maintenance by default. The 2026-05-27 strategic assessment (`.planning/NEXT-STEP-ASSESSMENT.md`) identified Actionable Recovery as the highest-leverage v1.1 wedge: wire the operator UI to actually execute runbook steps (Preview → Confirm) with 4–6 prebuilt recovery playbooks, audit propagation, and a demo seed that proves the loop. SLO-W1, Elixir/OTP CI matrix, supply-chain hardening, missing-guides work, and branch-protection enforcement move to v1.2 (Authoring DX & Maturity). Team workflow / responder coordination is v1.3. Cross-boundary journey correlation is v1.4+. None of these activate until a concrete PR-shaped slice opens.

## Current Milestone: v1.1 Actionable Recovery

**Goal:** Close the action loop in the operator UI — turn runbook steps into executable, audited, host-app-registered recovery actions with a safe Preview → Confirm flow. Replace today's hand-off-to-Grafana-or-Notion pattern with one-click in-UI mitigations.

**Target features:**
- Runbook capability-registration API (Behaviour-based, mirrors `Parapet.Integration`) so host apps declare named recovery actions parapet can dispatch
- Operator UI Guidance → Preview → Confirm flow (no auto-execution; Confirm wraps in `Parapet.Operator.ActionPayload` so circuit breaker + multi-node claim service apply for free)
- 4–6 prebuilt recovery playbooks for JTBD-MAP failure modes: retry storm, suppression drift, stalled async, dead-letter drain, deploy-tied incident, cardinality blowout
- Audit propagation — every action emits a `TimelineEntry` (`type: :recovery_action`) + `ToolAudit` row
- Demo seed — fresh demo app shows at least one runbook with a Preview-able + Confirm-able action wired up

**Started:** 2026-05-27. Seed thread: `.planning/threads/actionable-recovery-design.md`. Strategic context: `.planning/NEXT-STEP-ASSESSMENT.md`.

## Previous Posture: Released Maintenance

**Goal:** Preserve the stable-main 1.x posture and remain quiet by default unless there is concrete release-affecting work or a scoped PR-shaped feature slice worth opening.

**Posture:** Released product, quiet by default. `main` stays green and releasable; version cuts happen through Release Please PRs, not ad hoc tagging or auto-publish-on-every-merge. Serious feature work is PR-only and should not become ambient milestone churn.

**Candidate follow-up work (per 2026-05-27 strategic assessment):**

- **v1.1 — Actionable Recovery (the wedge):** Operator UI executes runbook steps via Guidance → Preview → Confirm; 4–6 prebuilt recovery playbooks (retry storm, suppression drift, stalled async, dead-letter drain, deploy-tied incident, cardinality blowout); audit propagation via `Parapet.Operator.ActionPayload` so circuit breaker + multi-node claim service apply for free; demo seed wires at least one Preview-able + Confirm-able action. **In scope:** operator-in-the-loop execution only. **Out of scope:** autonomous remediation, cross-app correlation, multi-tenant action scoping. Thread: `.planning/threads/actionable-recovery-design.md`.
- **v1.2 — Authoring DX & Maturity:** SLO-W1 as flag-based `mix parapet.gen.slo` Igniter task; multi-version Elixir/OTP CI matrix; supply-chain hardening (SHA-pinned actions, Dependabot, `MAINTAINING.md`, hexdocs logo/favicon); v0.x → v1.0 migration guide; deployment guide; branch-protection enforcement (make `release_gate` truly required, close the admin bypass) + conventional-commit taxonomy codified in `CONTRIBUTING.md` + PR template. Thread: `.planning/threads/release-gate-enforcement.md`.
- **v1.3 — Team Workflow & Coordination (JTBD #2):** Responder model, handoff/acknowledgement formalization, on-call rotation hooks (PagerDuty/Opsgenie/webhook adapter).
- **v1.4+ — Cross-boundary journey correlation (JTBD #4) + vertical starter packs** for non-Phoenix-default verticals.

**Decisions surfaced 2026-05-27:**
- **In scope (v1.1):** operator UI executes runbooks; preview-before-mutate is the safety posture.
- **Out of scope (permanent):** autonomous (no-human) remediation; replacing the operator's Grafana / log tool; hosted SaaS control plane.
- **Deferred to v1.4+:** multi-tenant SLO scoping and per-org operator views.
- **Dropped earlier:** SLO-B1's formal Bundle abstraction (superseded by the documented Provider pattern).

**Activation rule:** candidate work stays parked until a concrete slice is ready to be worked through a PR without weakening the stable-main posture.

**Key context:** The public surface is already frozen under `docs/stability.md`; future work should assume that contract. Research backing the additive follow-up still lives in `.planning/research/V1-*.md`. The 2026-05-27 strategic assessment lives at `.planning/NEXT-STEP-ASSESSMENT.md` and expires when v1.1 ships.

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
- ✓ hex.pm package metadata populated — `links:` (GitHub/HexDocs/Issues + Changelog), `:description`, `source_url`, and a `docs:` extras block — v0.10 Phase 15 (ADOPT-01)
- ✓ Root `CHANGELOG.md` (Release-Please-owned header-only stub) + retroactive `docs/HISTORY.md` covering v0.1–v0.9, with `CHANGELOG*` in the Hex `files:` whitelist — v0.10 Phase 15 (ADOPT-02)
- ✓ WebSaaS SLO starter pack — one-line registration of HTTP availability + LoginJourney + Oban job-success via `Parapet.SLO.StarterPack.WebSaaS` with documented default objectives in human terms — v0.10 Phase 16 (SLO-01)
- ✓ DeliverySaaS SLO starter pack — extends WebSaaS with Mailglass + Chimeway delivery slices that register only when those providers are configured (compile out cleanly otherwise); every pack slice is low-cardinality with a non-zero denominator guard and rides the existing multi-burn-rate Generator unchanged — v0.10 Phase 16 (SLO-02)
- ✓ Getting-started guide — install → first running SLO → first generated Prometheus alert in under 30 minutes, zero raw PromQL, referencing the WebSaaS starter pack (manual provider step explicit; names all three `gen.prometheus` outputs) — v0.10 Phase 18 (ADOPT-03)
- ✓ Troubleshooting guide — five predictable first-obstacle Q&A (blank Prometheus target, doctor warn-vs-error/`--ci`, Oban compile-out, multi-node uniqueness, Fly.io deploy hook) mapped to real doctor/install behavior — v0.10 Phase 18 (ADOPT-04)
- ✓ Per-integration guides — consistent Sigra/Accrue/Rulestead/Threadline guides (prerequisites, honest "what it unlocks", uniform activation line, config keys, troubleshooting), backed by a new `Parapet.Integration` behaviour that makes `Parapet.attach(adapters: […])` uniform and crash-proof across all eight adapters (fixes the Rulestead `attach/0` defect) — v0.10 Phase 18 (ADOPT-05)
- ✓ SLO authoring guide — journey-slicing decision tree with good-vs-bad examples anchored to the real WebSaaS slices — v0.10 Phase 18 (SLO-03)
- ✓ Low-traffic / low-volume SLO guardrails — documents the exact engine output (the rendered `min_total_rate: 0.01` denominator guard, the six multi-burn windows, synthetic-probe fallback) and names the "lower-the-objective" anti-pattern explicitly — v0.10 Phase 18 (SLO-04)

### Active

<!-- v1.0 Stable Release shipped 2026-05-26. Quiet stable-line mode is the default until a new PR-shaped slice is explicitly opened. -->

No active feature milestone by default. The shipped v1.0 requirements remain the current frozen baseline in `.planning/REQUIREMENTS.md`, and candidate post-1.0 work should open as explicit PR-scoped slices before it becomes active milestone state.

Carried forward beyond v1.0:

- **SLO-W1** (v1.1): `mix parapet.gen.slo` reshaped as a flag-based Igniter task (interactive-wizard form rejected as non-idiomatic — Igniter has no prompt API).
- Multi-version Elixir/OTP CI matrix, logo/favicon, `MAINTAINING.md`, SHA-pinned CI actions, demo Docker Compose (post-1.0 maturity items).

Dropped:

- **SLO-B1** cross-integration SLO bundles — superseded; `Parapet.SLO.Provider` returning multiple slices already is the bundle abstraction (`DeliverySaaS` proves it). Documented as a pattern in the SLO authoring guide instead.

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
Shipped v0.10 adding Adopter Success: a credibility-gate release (no new runtime deps, Ecto schemas, or Oban queues) over 4 phases / 12 plans in ~2 days — hex.pm metadata + Release-Please CHANGELOG, one-line SLO starter packs, an end-to-end `warning:` runbook surface with deepened + new preview-first templates, and seven adoption guides backed by a uniform `Parapet.Integration` activation behaviour. ~764 LOC of source change + ~697 lines of docs. First audit returned `tech_debt`; a same-day closure pass resolved the adopter-facing items, and the milestone audit `passed`.

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
| Release-Please-owned CHANGELOG body + retroactive `docs/HISTORY.md` | Human-edited history never conflicts with generated changelog entries; retroactive v0.1–v0.9 history lives outside the changelog body | ✓ Good |
| Opinionated SLO starter packs over auto-generated targets | One-line `WebSaaS`/`DeliverySaaS` packs with documented objectives beat silent auto-targets that become false safety guarantees | ✓ Good |
| Provider-gated delivery slices (`Code.ensure_loaded?` on parameterized atoms) | DeliverySaaS delivery slices register only when Mailglass/Chimeway are configured, compiling out cleanly otherwise | ✓ Good |
| Non-zero denominator guard on every pack slice (`min_total_rate`) | Low-traffic services don't flap; packs stay trustworthy without per-adopter tuning | ✓ Good |
| `warning:` as a first-class rendered runbook step annotation | Elixir silently swallows unknown macro keyword args — the surface had to be wired DSL→projection→UI before any template could rely on it | ✓ Good |
| Guidance-only runbooks where no allowlisted capability fits | `retry_storm`/`suppression_drift` stay advisory rather than executing mitigations that worsen the failure (e.g., retrying a storm) | ✓ Good |
| `Parapet.Integration` behaviour for uniform activation | Every adapter activates via the same `Parapet.attach(adapters: […])` line, crash-proof; fixes the Rulestead `attach/0` defect | ✓ Good |
| Code surfaces land before the docs that name them | Phase 16/17 code shipped before Phase 18 docs, so guides never reference uncompilable code | ✓ Good |

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
*Last updated: 2026-05-25 — v1.0 Stable Release milestone defined*
