# Parapet

## What This Is

Parapet is an open-source Phoenix reliability layer for Elixir SaaS teams: an opinionated SRE substrate that turns existing telemetry into safe metrics, user-journey SLOs, deploy correlation, incident evidence, runbooks, doctor checks, and operator-grade diagnostics. It composes Phoenix, Ecto, Oban, OpenTelemetry, Prometheus, and Grafana into a coherent reliability story without replacing any of them. The target adopter is a Phoenix SaaS team that has good tools but no paved road connecting them.

## Core Value

A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## Current Milestone: v1.8 CI/CD Performance & DX

**Goal:** Make the CI pipeline fast, cheap, and green-by-default — so contributors get quick honest signal and `main` stays a trustworthy release backstop. Pipeline/DX work only; public API + telemetry contracts stay frozen.

**Target features:**
- Dialyzer PLT caching — stop rebuilding the PLT on every run
- `concurrency: cancel-in-progress` on PR workflows — kill superseded runs
- Lint-once — run format/credo/etc. a single time, not per-matrix-cell
- `mix ci` alias — one local command mirroring the CI gate
- `Process.sleep` removal — deflake timing-based tests
- 3-OTP matrix scoped to main + nightly (trimmed PR breadth, full coverage on merge/nightly)
- Quarantine the two pre-existing test reds (`DocsPhase33Test`, `Telemetry.RecoveryActionTest`) so bare `mix test` is green — closes v1.7 tech-debt #6 and backs the "CI is the enforcement backstop" claim

**Key context:** v1.7's dual-prefix CI matrix interacts with this pipeline reshape — sequence carefully so no leg false-greens. Tech-debt #6 (test-red quarantine) is folded into v1.8 (not v1.9) per the 2026-07-02 milestone-definition decision, since v1.8's green-suite premise depends on it.

## Current State

**Shipped:** v1.7 Postgres Schema Isolation & Upgrade Path (2026-07-02) — Moved Parapet's six spine tables into a dedicated, configurable `parapet` Postgres schema by default via a compile-time `@schema_prefix` (shared `use Parapet.Spine.Schema` macro; `nil`/`""`/`"public"` ⇒ unprefixed; runtime `prefix:` banned by a static guard to avoid split-brain), proved the prefix propagates across every read/write with zero call-site edits, and validated both legs with a dual-prefix CI matrix (prefix-namespaced `_build`, `mix compile --force`). Shipped schema-aware generators + all 8 committed migrations (first-ordered `CREATE SCHEMA` sentinel, `--no-create-schema` DBA hatch), two opt-in upgrade tracks for existing adopters (Track A stay-on-`public`; Track B a reversible single-transaction `SET SCHEMA` move with pre-flight guards + round-trip DB test), a `parapet.doctor` drift/existence check, a real-host demo smoke proof, and `docs/upgrade-1.x.md` closing the audited #1 documentation gap — all with public API + telemetry contracts provably frozen. 6/6 phases, 29/29 requirements; audit `tech_debt` (zero requirement/integration/flow blockers — remaining items are internal hygiene; see `.planning/milestones/v1.7-MILESTONE-AUDIT.md`). Verified closeout.

<details>
<summary><b>Archived State Updates</b></summary>

**Previously shipped:** v1.6 Operator UI Brand & Design-System Audit (2026-06-29) — Re-skinned the generated, host-owned Operator UI to the v1.5 brand book via values-only edits to `operator_theme_bootstrap/1` (brand neutrals/signals, six status triplets, IBM Plex type scale, 8px grid, radius/shadow/motion tokens, per-surface focus rings) with zero public-API/telemetry/host-ownership change, vendored five subsetted IBM Plex woff2 faces (52.2 KB), ran a layer-by-layer WCAG 2.2 AA design-system audit fixing real usability bugs, and installed forward-only regression guardrails (byte-parity, off-palette gate, motion assertion, screenshot manifest, evidence-binding audit). 7/7 phases, 61/68 requirements (7 shipped+human-verified but not yet ExUnit-pinned); audit passed (see `.planning/milestones/v1.6-MILESTONE-AUDIT.md`).

**Previously shipped:** v1.5 Brand Book & Logo System (2026-06-24) — Operationalized the brand research into a repo-lean (192 KB) self-contained HTML brand book under `brandbook/`: locked corbelled-tower stacked emblem (Space Grotesk, outlined to paths), CSS+JSON design tokens, a WCAG AA contrast matrix, component/landing/README collateral, and a zero-config swap of the off-brand HexDocs logo + favicon. SVG/HTML/CSS/JSON only — no rasters or font binaries; public API and telemetry contract untouched. 4/4 phases, 13/13 requirements (see `.planning/milestones/v1.5-MILESTONE-AUDIT.md`).

**Previously shipped:** v1.4 Trust Hardening & Host-App Compatibility (2026-06-04) — Closed the repo-evidenced adoption-trust gaps most likely to hurt real host-app use: archive/export/prune now preserves complete Parapet-owned evidence bundles or fails loudly with structured run context; generated Operator UI links and patches respect default and nested host scopes such as `/ops/parapet`; and first-contact docs explain archive maintenance, scoped mounting, and the v1.4 quality-evaluation closeout.

**Previously shipped:** v1.3 Operator UI Polish & Design System (2026-06-04) — Completed the generated Operator UI polish pass: reframed `/parapet` around active response, explicit response/actions/history lanes, and preferred incident detail navigation; consolidated generated Tailwind component helpers and audit-safe action copy; expanded demo state coverage; and captured browser screenshot proof across desktop and mobile routes.

**Previously shipped:** v1.2 Authoring DX & Maturity (2026-06-03) — Completed the stable-line maturity pass: moved SLO and capability dynamic state to ETS-backed checkout isolation, shipped the flag-based `mix parapet.gen.slo` Igniter task, hardened CI with an Elixir/OTP matrix and SHA-pinned actions, added Dependabot and branch-protection guidance, published migration/deployment docs with HexDocs branding, and documented maintainer/contributor/demo Compose workflows.

**Previously shipped:** v1.1 Actionable Recovery (2026-06-03) — Closed the action loop in the operator UI. Turned runbook steps into executable, audited, host-app-registered recovery actions with a safe Preview → Confirm flow. Shipped the capability-registration behaviour (`Parapet.Recovery`), 6 prebuilt recovery playbooks, audit propagation (TimelineEntry and ToolAudit), and a demo seed that proves the loop. `Parapet.Recovery` graduated to Stable.

**Previously shipped:** v1.0 Stable Release (2026-05-26) — froze the public API + telemetry contract under documented stability tiers and a deprecation policy, completed governance/docs trust surfaces, shipped a runnable demo app as a CI contract test, hardened CI into release-quality lanes, automated Hex publishing from Release Please, and cut the live `v1.0.0` release.

**Previously shipped:** v0.10 Adopter Success (2026-05-24) — closed the gap between "feature-complete" and "adoptable by a stranger" without expanding feature surface.

</details>

## Posture: Released Maintenance

**Goal:** Preserve the stable-main 1.x posture and remain quiet by default unless there is concrete release-affecting work or a scoped PR-shaped feature slice worth opening.

**Posture:** Released product, quiet by default. `main` stays green and releasable; version cuts happen through Release Please PRs, not ad hoc tagging or auto-publish-on-every-merge. Serious feature work is PR-only and should not become ambient milestone churn.

**Candidate follow-up work (per 2026-05-27 strategic assessment):**

- **v1.1 — Actionable Recovery (the wedge):** Operator UI executes runbook steps via Guidance → Preview → Confirm; 4–6 prebuilt recovery playbooks (retry storm, suppression drift, stalled async, dead-letter drain, deploy-tied incident, cardinality blowout); audit propagation via `Parapet.Operator.ActionPayload` so circuit breaker + multi-node claim service apply for free; demo seed wires at least one Preview-able + Confirm-able action. **In scope:** operator-in-the-loop execution only. **Out of scope:** autonomous remediation, cross-app correlation, multi-tenant action scoping. Thread: `.planning/threads/actionable-recovery-design.md`.
- **v1.2 — Authoring DX & Maturity:** SLO-W1 as flag-based `mix parapet.gen.slo` Igniter task; multi-version Elixir/OTP CI matrix; supply-chain hardening (SHA-pinned actions, Dependabot, `MAINTAINING.md`, hexdocs logo/favicon); v0.x → v1.0 migration guide; deployment guide; branch-protection enforcement (make `release_gate` truly required, close the admin bypass) + conventional-commit taxonomy codified in `CONTRIBUTING.md` + PR template. Thread: `.planning/threads/release-gate-enforcement.md`.

**Decisions surfaced 2026-05-27:**
- **In scope (v1.1):** operator UI executes runbooks; preview-before-mutate is the safety posture.
- **Out of scope (permanent):** autonomous (no-human) remediation; replacing the operator's Grafana / log tool; hosted SaaS control plane; Team Workflow & Coordination (JTBD #2) such as PagerDuty routing, as the target audience is strictly solo operators; Cross-boundary journey correlation.
- **Deferred to v1.5+:** multi-tenant SLO scoping and per-org operator views.
- **Dropped earlier:** SLO-B1's formal Bundle abstraction (superseded by the documented Provider pattern).

**Activation rule:** candidate work stays parked until a concrete slice is ready to be worked through a PR without weakening the stable-main posture.

**Key context:** The public surface is already frozen under `docs/stability.md`; future work should assume that contract. Research backing the additive follow-up still lives in `.planning/research/V1-*.md`. The 2026-05-27 strategic assessment lives at `.planning/NEXT-STEP-ASSESSMENT.md` and expires when v1.1 ships.

## Next Milestone Goals

Not yet defined. Define the next milestone with `$gsd-new-milestone`. Candidate inputs:

- **Close the v1.6 automated-coverage gaps:** ExUnit-pin TOKEN-04 (explicit `--radius-*` custom properties) and the Phase-48 FLOW/COPY/A11Y-06 rendered states so the human-verified facts become regression-guarded.
- **Token → Tailwind/daisyUI theme generator + HEEx snippets** for the generated Operator UI (v1.6 adopted token *values* in-place; the generator is separate-concern scope).
- **Brand follow-ups deferred from v1.5/v1.6:** raster/OpenGraph exports, animated/motion logo, Figma source-of-truth, multi-page PDF brand book.
- **Stable telemetry manifest** (`telemetry_stable.json` + drift gate) — the durable WR-01 fix deferred per D-21.
- Automated browser a11y/interaction testing (Playwright + axe-core) as demo dev-dependencies.
- Still-open quality-evaluation findings carried from prior milestones; long-tail cross-boundary journey correlation; MCP/recovery extensions after MCP stability improves.

## Requirements

### Validated

- ✓ Compile-time schema-prefix core & propagation — `use Parapet.Spine.Schema` macro (default `parapet`, `nil`/`""`/`"public"` opt-out) across all six spine schemas, `config/config.exs` env seam, `Evidence.schema_prefix/0` runtime mirror, prefix-qualified test bootstrap; the prefix rides every select/join/`insert_all`/Multi with zero call-site edits, runtime `prefix:` banned by a static guard, and a dual-prefix CI matrix (prefix-namespaced `_build` + `mix compile --force`) proves both legs honestly — v1.7 (PREFIX-01..04, PROP-01..03, TEST-01..03)
- ✓ Schema-aware generators & library migrations — first-ordered `CREATE SCHEMA` sentinel, `prefix:`-stamped DDL across all 8 committed migrations + `gen.spine`/`gen.archive_indexes`, no-clobber `configure_new` config write, `--schema`/`--no-create-schema` least-privilege hatch, one shared resolver — v1.7 (GEN-01..07)
- ✓ Tested opt-in upgrade path & doctor — Track A stay-on-`public` pin, `mix parapet.gen.schema.move` reversible single-transaction `SET SCHEMA` with pre-flight abort guards + second-move refusal + throwaway-DB round-trip, `parapet.doctor` config↔compiled drift + schema-existence check; upgrading never forces a migration (default flips for new installs only) — v1.7 (UPG-01..05, DOCTOR-01)
- ✓ Demo real-host proof, upgrade docs & frozen-contract hardening — demo migrates end-to-end into `parapet` (six-table + `get_meta` smoke), `docs/upgrade-1.x.md` single-sources copy-paste Track A/B (closing the audited #1 doc gap), `verify.public_api` zero-drift + telemetry `:source` bare-name assertion prove both contracts frozen, two-part honest `feat(schema)` CHANGELOG — v1.7 (DOC-01..02, SAFE-01..04)
- ✓ Single `parapet` Hex package with a narrow, explicit public surface and `files:` whitelist — v0.1
- ✓ Documented telemetry contract treated as public API — redaction-safe, low-cardinality by default — v0.1
- ✓ Add `lease_until` column to `parapet_action_claims` — v1.1 (FND-01)
- ✓ Define `Parapet.Telemetry.RecoveryAction` event family — v1.1 (FND-02)
- ✓ Expose `Parapet.Recovery` behaviour for capability registration — v1.1 (RCV-01)
- ✓ `Parapet.Recovery.attach/1` gracefully skips unloaded modules — v1.1 (RCV-02)
- ✓ Widen `Parapet.Capabilities` allowlist for v1.1 capabilities — v1.1 (RCV-03)
- ✓ LiveView UI displays preview of mitigation (target args, expected diff) — v1.1 (UI-01)
- ✓ LiveView renders conflict and short-circuit variants with actionable next steps — v1.1 (UI-02, UI-03, UI-04)
- ✓ Every executed runbook step writes a `TimelineEntry` and `ToolAudit` — v1.1 (AUD-01, AUD-02, AUD-03)
- ✓ Prebuilt runbook templates for JTBD-MAP failure modes (retry storm, stalled async, etc.) — v1.1 (PB-01 to PB-06)
- ✓ Demo app seeded with a capability-backed open incident — v1.1 (DEMO-05, DEMO-06)
- ✓ `Parapet.Recovery` declared Stable with CHANGELOG migration notes — v1.1 (STAB-07)
- ✓ Scaffolding generator `mix parapet.gen.recovery` and `check_recovery` doctor check — v1.1 (ADOP-01, ADOP-02)
- ✓ `docs/recovery-actions.md` adopter guide — v1.1 (ADOP-03)
- ✓ Flag-based `mix parapet.gen.slo` Igniter task — v1.2 (DX-01)
- ✓ `Parapet.SLO` registry state moved off global dynamic Application env mutation into ETS checkout isolation — v1.2 (DX-02)
- ✓ v0.x -> v1.0 migration guide — v1.2 (DX-03)
- ✓ Deployment guide — v1.2 (DX-04)
- ✓ Multi-version Elixir/OTP CI matrix — v1.2 (MAT-01)
- ✓ SHA-pinned GitHub Actions — v1.2 (MAT-02)
- ✓ Dependabot for Hex and GitHub Actions — v1.2 (MAT-03)
- ✓ Branch protection guidance enforcing `release_gate` — v1.2 (MAT-04)
- ✓ `MAINTAINING.md` release procedures — v1.2 (MAT-05)
- ✓ Conventional Commit taxonomy in `CONTRIBUTING.md` — v1.2 (MAT-06)
- ✓ HexDocs logo and favicon — v1.2 (MAT-07)
- ✓ Demo app Docker Compose path — v1.2 (MAT-08)
- ✓ Archive durability hardening — resolved evidence archive/export/prune preserves complete durable evidence, fails loudly on partial failure, and exposes actionable run summaries — v1.4 (ARCH-01 to ARCH-04)
- ✓ Generated UI scoped-route compatibility — generated Operator UI works under default `/parapet` and nested host-owned scopes such as `/ops/parapet` without taking auth/router ownership — v1.4 (UIROUTE-01 to UIROUTE-03)
- ✓ Adoption proof and docs — archive maintenance and scoped UI mounting are documented, tested, and reflected in the quality-evaluation follow-up trail — v1.4 (ADOPT-01 to ADOPT-03)
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
- ✓ Brand pressure-test — distilled cite-backed brand reference, WCAG AA contrast matrix, and frozen off-brand anti-criteria + logo acceptance checklist — v1.5 (BRAND-01 to BRAND-03)
- ✓ Logo system — locked corbelled-tower stacked emblem (Space Grotesk, outlined) via a 6-round comparison-gallery tournament with monochrome/16px reduction proof and a hard human selection gate — v1.5 (LOGO-01 to LOGO-04)
- ✓ Token system & HTML brand book — `tokens.css` + `tokens.json` verbatim from the research doc, full winning-logo variation set, and a self-contained `file://`-openable `brandbook/index.html` — v1.5 (TOKEN-01 to TOKEN-03)
- ✓ Collateral, wiring & hygiene — token-driven component/landing/README collateral, zero-config path-stable HexDocs logo/favicon swap, and a passing repo-hygiene audit (palette-clean, binary-free, 192 KB) — v1.5 (COLLAT-01 to COLLAT-03)
- ✓ Operator-UI brand token re-skin — values-only retheme of `operator_theme_bootstrap/1` to brand neutrals/signals + six status triplets, IBM Plex type scale, 8px grid, radius/shadow/motion tokens, per-surface focus rings; no public-API/telemetry/markup-color change — v1.6 (TOKEN-01..03, TOKEN-05, MOTION-01..03, A11Y-01)
- ✓ Self-hosted IBM Plex woff2 — five subsetted latin faces (52.2 KB) served from host static path with `font-display: swap` + system fallback, wired by the generator — v1.6 (FONT-01 to FONT-03)
- ✓ Primitive, nav/shell, data-display & meta-component audit — buttons/links/badges/chips/status-pills/forms, nav/tabs/cockpit shell, incident list/timeline/tables, response cockpit/preview/overlays with correct stacking, focus trap/restore, 390px usability, color-blind-safe states — v1.6 (COMP-01..08, FORM-01..02, NAV-01..05, DATA-01..06, GROUP-01..06, A11Y-02..05)
- ✓ WCAG 2.2 AA contrast gate re-pinned to brand hexes — six status triplets, dark links `#7FB4C6`, focus rings at the 3:1 UI floor; dark warning button fixed 2.9:1 → 5.62:1 — v1.6 (GUARD-02)
- ✓ Demo stress fixtures & gallery — `/parapet/_gallery` lab, five `PARAPET_DEMO_SCENARIO` stress scenarios, screenshot capture across desktop+mobile / light+dark with a demo contract test — v1.6 (FIXTURE-01..05, GALLERY-01..02)
- ✓ Forward-only regression guardrails — template↔demo byte-parity, fail-closed off-palette-hex gate, motion/reduced-motion assertion, committed screenshot baseline manifest + CI drift gate, evidence-binding `v1.6-MILESTONE-AUDIT.md` — v1.6 (GUARD-01, GUARD-03 to GUARD-07)

### Active

**v1.8 CI/CD performance & DX** (next milestone in the approved v1.7→v1.9 roadmap — define with `/gsd-new-milestone`):

- [ ] `CI-01` — Dialyzer PLT caching, `concurrency: cancel-in-progress` (PR), lint-once, `mix ci` alias, `Process.sleep` removal, 3-OTP matrix → main+nightly. *Note: v1.7's dual-prefix matrix interacts with this pipeline reshape — sequence accordingly. Also fold in v1.7 tech-debt item #6 (quarantine the pre-existing `DocsPhase33Test` + `Telemetry.RecoveryActionTest` reds so bare `mix test` is green).*

**v1.6 automated-coverage gaps** (shipped + human-verified in the live UI; gap is in ExUnit coverage, not the console — close in a future milestone):

- [ ] **TOKEN-04** — type-scale / spacing / radius applied without layout shift; functional via Tailwind brand-scale utilities, not yet systematized as explicit `--radius-*` custom properties. Visual layout-shift check is manual-only per `48-VALIDATION.md`.
- [ ] **FLOW-01..05, COPY-01..05, A11Y-06** — Phase-48 pages/flows/microcopy/landmarks shipped and human-verified via the `/parapet/_gallery` walkthrough; not yet pinned by ExUnit rendered-state assertions.

Dropped:

- **SLO-B1** cross-integration SLO bundles — superseded; `Parapet.SLO.Provider` returning multiple slices already is the bundle abstraction (`DeliverySaaS` proves it). Documented as a pattern in the SLO authoring guide instead.

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Team Workflow & Coordination (e.g., PagerDuty routing, shift handoffs) — Target audience is solo operators, not ops teams
- Cross-boundary journey correlation — Better handled by dedicated tracing tools (e.g. OpenTelemetry)
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

Shipped v1.1 Actionable Recovery adding an operator-in-the-loop action execution flow via Guidance → Preview → Confirm. Added the `Parapet.Recovery` behaviour, six prebuilt playbooks, and audit propagation. Demo seeded with a complete end-to-end confirm loop.
Shipped v1.2 Authoring DX & Maturity adding ETS-backed state isolation for SLO/capability registries, a flag-based SLO Igniter task, CI matrix and supply-chain hardening, migration/deployment guides, release-maintenance docs, HexDocs branding, and a validated demo Compose path.
Shipped v1.3 Operator UI Polish & Design System adding active-response-first generated UI navigation, private Tailwind helper families, richer demo state coverage, and browser screenshot proof without adding repo dependencies.
Shipped v1.4 Trust Hardening & Host-App Compatibility adding durable archive evidence bundles and structured failure context, scoped generated Operator UI routes for host-owned mount paths, and copy-pasteable adoption docs backed by focused guard tests.
Shipped v1.5 Brand Book & Logo System: a docs/brand-assets-only milestone (no source, public API, or telemetry change) operationalizing the 1,874-line brand research into a self-contained 192 KB `brandbook/` — a locked corbelled-tower stacked emblem (Space Grotesk, outlined to paths) chosen via a 6-round tournament, CSS+JSON design tokens, a WCAG AA matrix, `file://`-openable HTML brand book + collateral, and a zero-config path-stable swap of the off-brand HexDocs logo/favicon. SVG/HTML/CSS/JSON only — zero rasters, zero font binaries. 4 phases / 11 plans over 2 days; audit `passed` 13/13.
Shipped v1.6 Operator UI Brand & Design-System Audit: applied the v1.5 brand to the generated, host-owned Operator UI — values-only retheme of `operator_theme_bootstrap/1` across all three EEx templates (+ byte-parity demo mirrors), five subsetted IBM Plex woff2 faces (52.2 KB; the only relaxation of v1.5's no-font-binaries rule, scoped to operator fonts), and a layer-by-layer WCAG 2.2 AA usability audit (scrim/modal stacking, focus trap/restore, fake-disabled controls, dark-mode legibility, 390px overflow, designed empty/loading/error states, brand-voice microcopy). Added a demo-only `/parapet/_gallery` stress lab, five `PARAPET_DEMO_SCENARIO` fixtures, and forward-only guardrails (byte-parity, off-palette gate, motion assertion, screenshot manifest + CI drift gate, evidence-binding audit). No public-API/telemetry/host-ownership drift. 7 phases / 25 plans over 5 days; audit `passed` 61/68 (7 shipped+human-verified but not yet ExUnit-pinned). Closed `override_closeout` with 3 documented verification overrides.
Shipped v1.7 Postgres Schema Isolation & Upgrade Path: moved the six spine tables into a configurable `parapet` schema by default via a compile-time `@schema_prefix` (shared `use Parapet.Spine.Schema` macro; runtime `prefix:` banned to avoid split-brain), proved propagation across every read/write with zero call-site edits under a dual-prefix CI matrix, shipped schema-aware generators + all 8 committed migrations, two opt-in upgrade tracks (stay-on-`public` / reversible `SET SCHEMA` move with round-trip test), a `parapet.doctor` drift check, a real-host demo smoke, and `docs/upgrade-1.x.md` — public API + telemetry frozen throughout. 47 source files changed (+3,898/−169) across 6 phases / 21 plans over 4 days. Audit `tech_debt`: 29/29 requirements, 7/7 integration seams, 4/4 e2e flows, zero blockers; remaining debt is internal hygiene (Nyquist draft records, frontmatter omissions, an accepted OTP-coverage prune, doc-build warnings, and two pre-existing test reds tracked for v1.8/v1.9). Verified closeout.

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
| Operator-in-the-loop execution only | Safety posture for v1.1 avoids autonomous remediation risks | ✓ Good |
| Telemetry contract locked before capability ship | Irreversible on publish under v1.0 freeze | ✓ Good |
| Capabilities Agent, not Application env | Avoids repeating the SLO config mistake and prevents state bleeding | ✓ Good |
| Route Confirm through ClaimService | Ensures identical claim-protection and circuit-breaking as Oban execution | ✓ Good |
| 5-minute Preview expiry | Ensures operator acts on fresh target state | ✓ Good |
| Guidance-only runbooks | Retry Storm and Suppression Drift intentionally lack capability references to avoid worsening failures | ✓ Good |
| Code surfaces land before the docs | Ensures guides never reference uncompilable code | ✓ Good |
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
| ETS checkout isolation for dynamic library state | Avoids test bleed and keeps host-owned runtime behavior compatible with the stable API | ✓ Good |
| `release_gate` remains the stable aggregate CI check | Lets branch protection stay stable while underlying jobs expand into an Elixir/OTP matrix | ✓ Good |
| Generated Operator UI remains host-owned | v1.3 polish improves templates and demo mirrors without adding Parapet-owned auth, router, runtime UI dependency, or stable API changes | ✓ Good |
| Preferred detail route plus compatibility route | `/parapet/incidents/:id` improves generated navigation clarity while `/parapet/:id` remains documented and test-pinned for adopters | ✓ Good |
| Generated component helpers stay private to copied LiveViews | Consolidates Tailwind surfaces and controls without creating a new public design-system module or dependency | ✓ Good |
| Browser screenshot proof without repo dependencies | Local Chromium script verifies desktop/mobile generated UI paths while avoiding a new browser-test dependency surface | ✓ Good |
| Complete archive evidence bundle before prune | Archive maintenance serializes incident, timeline, tool audit, action item, and action claim records before exact-id deletion | ✓ Good |
| Structured archive failures over silent success | Summary/Failure tuples and CLI failure context make partial archive persistence/export/delete failures actionable | ✓ Good |
| Scoped route ownership stays in generated host-owned code | Supports `/parapet` and nested scopes like `/ops/parapet` without adding Parapet router/auth ownership or generator flags | ✓ Good |
| Quality closeout as dated addendum | Preserves the original quality evaluation as historical input while documenting exactly which v1.4 risks closed | ✓ Good |
| Repo-lean brand book: SVG/HTML/CSS/JSON only, zero binaries | Keeps `brandbook/` at 192 KB (≤ 250 KB), enforced by a grep/`du`/scope QA gate — no raster or font bloat creeping into the repo | ✓ Good |
| Logo outlined to paths, not font-dependent | Assets render identically everywhere without shipping a font binary; preserves the repo-lean constraint while keeping the Space Grotesk typemark exact | ✓ Good |
| Hard human selection gate before downstream brand work | A 6-round tournament locked the identity (D-003) before any token or brand-book build — prevents rework on a contested mark | ✓ Good |
| Zero-config path-stable HexDocs swap | Replaced `docs/assets/parapet-logo.svg`/`favicon.svg` in place so `mix.exs` doc paths stay unchanged — on-brand HexDocs with no config edit | ✓ Good |
| Brand research is operationalized, not re-litigated | Every token/value cited back to the source research doc; nothing re-derived — keeps the brand strategy single-sourced | ✓ Good |
| Self-hosted IBM Plex woff2 over CDN/system-only (v1.6) | Operator console runs in air-gapped/privacy-sensitive contexts; self-hosted subsetted fonts give offline, no-CDN, pixel-consistent brand type with no FOUT — accepted cost is relaxing the "no font binaries" rule for operator-UI fonts only (`brandbook/` stays binary-free), bounded by latin-subset + needed-weights + a tracked package-size budget | ✓ Good |
| Operator-UI brand re-skin is values-only (v1.6) | Retheme by re-pointing the existing `--parapet-*`/`--po-*` CSS vars at brand values inside `operator_theme_bootstrap/1`; no class/selector/JS/markup-color change keeps the switcher, query-param, localStorage, and contrast test intact and the diff reviewable | ✓ Good |
| Watch-blue links/focus brightened on dark surfaces (v1.6) | Brand watch-blue fails WCAG AA on deep-slate (1.97:1) — dark links use `#7FB4C6` and focus rings flip to limestone, enforced by the contrast gate so the re-skin is provably AA on both themes | ✓ Good |
| Forward-only guardrails over retroactive snapshots (v1.6) | Byte-parity (`Code.format_string!`), a fail-closed off-palette-hex gate sourced live from `tokens.css`, a motion/reduced-motion assertion, and a committed screenshot manifest with a Postgres-free CI drift gate make the re-skin regression-proof going forward without new infra | ✓ Good |
| Milestone audit binds every requirement to a command/file:line (v1.6) | The GUARD-07 `v1.6-MILESTONE-AUDIT.md` 68-row evidence table + three non-regression proofs (public-API/host-ownership/telemetry) make the "no drift" claim verifiable rather than asserted | ✓ Good |
| Close v1.6 with documented overrides, not blocking on manual-only checks (v1.6) | TOKEN-04 layout-shift and Phase-48 rendered states are human-verified but ExUnit-unpinnable without browser tooling; recording them as `override_closeout` gaps keeps the shipped UI honest while parking the automated-coverage work for a future milestone | ⚠️ Revisit |
| Compile-time `@schema_prefix`, not runtime `prefix:` (v1.7) | A runtime `prefix:` option has read/write precedence asymmetry that causes split-brain queries; freezing the prefix at compile time via a shared macro makes it structurally impossible to thread a runtime prefix, enforced by a static guard test | ✓ Good |
| Config key `:schema_prefix`, never bare `:prefix` (v1.7) | Bare `:prefix` collides with the frozen telemetry "event prefix" contract; `:schema_prefix` keeps the two namespaces distinct | ✓ Good |
| Existing adopters opt-in only; default flips for new installs (v1.7) | Upgrading never forces a schema migration — do-nothing upgraders set `schema_prefix: nil` (Track A) or run the reversible `SET SCHEMA` move (Track B); avoids a breaking data move on `mix deps.update` | ✓ Good |
| No `search_path` switching (v1.7) | `search_path` would break `public`-resident extensions (`citext`, `uuid-ossp`, `pg_trgm`); Rails Apartment abandoned it over leak/pooling bugs — compile-time qualification sidesteps this | ✓ Good |
| Dual-prefix CI matrix with prefix-namespaced `_build` + `mix compile --force` (v1.7) | `@schema_prefix` is compile-time, so TEST-02 can't be proven at runtime; without a per-prefix `_build` cache key the `public` leg silently reuses the `parapet` build and false-greens | ✓ Good |
| Two-part honest CHANGELOG banner over "no action required" (v1.7) | The unqualified "No action required for existing installs" is factually false for do-nothing upgraders (their first spine query would hit the wrong schema); a distinct action-required line linking `docs/upgrade-1.x.md` is the honest framing (D-01/D-02 override of SAFE-04) | ✓ Good |
| Complete v1.7 tracking internal debt, not blocking on it (v1.7) | Audit `tech_debt` with 29/29 requirements and zero adopter-facing blockers; the register (Nyquist records, frontmatter, OTP-coverage prune, doc-build warnings, two pre-existing test reds) is internal hygiene routed to v1.8/v1.9 rather than a close blocker. D-11 OTP-coverage-prune item resolved by Phase 60 — see "Retire v1.7 D-11 CI-coverage prune" row below. | ✓ Good |
| Retire v1.7 D-11 CI-coverage prune (v1.8) | RESOLVED 2026-07-02 (Phase 60 / MATRIX-02): retired by design, not by fix. The full matrix now runs on main + nightly only, so the original solo-maintainer CI-budget reason for the prune is gone. The remaining parapet ×3-OTP / public ×1-OTP asymmetry is intentional — prefix resolution is compile-time and OTP-independent, so one OTP on the public leg is complete signal. | ✓ Good |

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
*Last updated: 2026-07-02 after v1.8 Phase 57 (Test Suite Baseline) — bare `mix test` reds fixed directly and all `Process.sleep` sites classified; TEST-01..05 verified, green enforced by the CI gate*
