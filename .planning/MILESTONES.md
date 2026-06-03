# Milestones

## v1.2 Authoring DX & Maturity (Shipped: 2026-06-03)

**Phases completed:** 4 phases, 6 plans, 10 tasks

**Key accomplishments:**

- Elixir/OTP CI matrix with SHA-pinned GitHub Actions and version-isolated caches
- Dependabot supply-chain monitoring plus branch protection instructions for required release_gate enforcement
- Adopter migration and deployment guides published through HexDocs with docs-local Parapet branding assets
- Maintainer release checklist, contributor commit taxonomy, and reproducible demo Compose smoke path

---

## v1.1 Actionable Recovery (Shipped: 2026-06-03)

**Phases completed:** 7 phases, 19 plans, 23 tasks

**Key accomplishments:**

- lease_until column backfill migration, ClaimService expired-claim self-heal (UPDATE-in-place), and automated Ecto.Migrator backfill integration test — FND-01 delivered end-to-end with zero human verification.
- `Parapet.Recovery` behaviour module with 4 frozen callbacks, minimal `__using__/1` macro, and crash-proof `attach/1` activation function that silently skips unloaded modules and registers loaded ones via function-capture bridge into `Parapet.Capabilities`
- 107 tests in `test/parapet/recovery_test.exs`: 7-sync + 100-async sweep covering all Phase 24 success criteria, with Pitfall 13 avoidance rationale embedded as comments in the async sweep module
- `Parapet.Operator.confirm_runbook_step/4` now routes through `ClaimService.claim_action/1` with `action_kind: "operator"`, surfaces two new additive return variants (`{:short_circuited, atom}` and `{:conflicted, uuid_string}`), and gates Confirm on a SHA-256 `target_refs_hash` consistency check — closing the v1.1 architectural defect where the operator-clicked path skipped the same claim protection the Oban auto-execution path already uses.
- The demo LiveView now renders all four return-tuple arms from `Parapet.Operator.confirm_runbook_step/4` with operator-actionable flash copy (including the verbatim ROADMAP-pinned conflict flash), and the Preview panel displays the capability's user-facing action name above the existing target/count grid — closing UI-01 ("action name in dedicated panel") and UI-04 ("LiveView renders both new branches with operator-actionable next steps").
- Provides unit coverage for the two new short-circuit branches (`:preview_expired`, `:target_refs_drift`) and a multi-node concurrency proof for the operator-confirm path. Closes the Wave 1 known red (operator_test.exs:495 happy-path) by extending the inline `DummyRepo` to handle `ClaimService.claim_action/1`'s raw-function transaction protocol.
- Six JTBD-MAP prebuilt runbook templates fully wired: two new capability templates (deploy_tied_incident via :revert_feature_flag, cardinality_blowout via :disable_metric_label) authored in the stalled_executor 3-step shape, suppression_drift guidance-only warning hardened with architectural rationale, generator updated to emit all six, test suite green at 491/0.
- Two compiled demo modules wiring :retry_async_item capability to a 3-step StalledExecutor runbook — the load-bearing prerequisites for boot registration (Plan 02) and CI scenarios (Plan 04)
- One-liner:
- One-liner:
- Parapet.Recovery graduated from Experimental to Stable via two-anchor flip: moduledoc admonition to `Stable {: .info}`, docs/stability.md row moved to Stable table, additive confirm_runbook_step/4 variants named in Deprecation Register, and Wave-0 regression guard added to verify.public_api tests
- One-liner:
- One-liner:
- One-liner:

---

## v1.0 Stable Release

**Date:** 2026-05-26 (`v1.0.0` tag; point releases `v1.0.1`–`v1.0.3` on 2026-05-27)
**Stats:**

- Phases: 19-22 (4 phases)
- Plans: 19 (18 with SUMMARY.md; 22-04 plan-only — see Known Gaps)
- Code change (v1.0.0 cut): 208 files, +13,670/−459
- Code change (incl. v1.0.1–v1.0.3 point releases): 230 files, +16,312/−536
- Timeline: 2026-05-25 → 2026-05-26 (~2 days for `v1.0.0`; +1 day for `v1.0.1`–`v1.0.3` point releases)
- Commits: 128 incl. planning (Phase 19 start through `v1.0.3`)
- Archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md), [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)

### Accomplishments

1. Froze Parapet's public surface under three named stability tiers (Stable / Experimental / Internal) and a written deprecation policy — every public module declares its tier via an ExDoc callout, every Stable function carries `@doc since: "1.0.0"`, `mix verify.public_api` is a hard gate, and `docs/stability.md` enumerates the surface with semver semantics and the soft-deprecation → hard-deprecation → removal cycle.
2. Locked the telemetry contract as a public API artifact: a `telemetry_contract_test` fails CI when any of the 27 frozen `[:parapet, …]` event families drifts on event name, measurement keys, metadata keys, or outcome atoms. `Parapet.SLO.define/2` is hard-deprecated with a compile-time warning naming `Parapet.SLO.Provider` as the replacement.
3. Closed the OSS-governance and integration-docs gaps blocking adopter trust: `CONTRIBUTING.md` + `SECURITY.md` shipped (GOV-03 `CODE_OF_CONDUCT.md` intentionally omitted), README states the 1.0 semver commitment and Elixir/OTP/Postgres compatibility matrix, four previously missing integration guides (Chimeway, Mailglass, Rindle, Scoria) match the established five-section template, the SLO authoring guide documents the Provider-as-bundle pattern, and HexDocs ships grouped extras with the getting-started guide as the landing page.
4. Shipped a runnable demo Phoenix app (`examples/demo_app/`) as a live CI contract test: path-dep on parapet, seeded with realistic evidence via the Evidence Stable API (open/investigating/resolved incidents, timeline entries, a tool audit, a runbook with a `warning:` step, registered WebSaaS SLO state), exposes the Operator UI at `/parapet`, runs a `demo` smoke job that's a required check in `release_gate`, and is excluded from the published Hex package. v1.0.1 closed the post-cut CR-02 gap by wiring the LiveView JS pipeline (esbuild + `assets/js/app.js` + deferred script tag).
5. Hardened CI into a release-quality contract: dedicated `lint` lane runs `compile --warnings-as-errors`, `compile --no-optional-deps --warnings-as-errors`, `docs --warnings-as-errors`, `credo --strict`, `dialyzer`, and `verify.public_api`; `release_gate` fan-in requires `lint` + `test` + `demo`; the Release Please workflow gates a Hex publish job on `release_created` with dry-run, publish, and post-publish package/HexDocs verification.
6. Cut `1.0.0` honestly through Release Please: staged `0.10.0 → 1.0.0` graduation via a one-time `release-as: "1.0.0"` pin (no manifest hand-edits), live `v1.0.0` tag on 2026-05-26, `https://hex.pm/packages/parapet` and `https://hexdocs.pm/parapet/1.0.0/` resolve, and `main` returned to steady-state Release Please config with the one-time pin and pre-1.0 `bump-minor-pre-major` + `bump-patch-for-minor-pre-major` flags removed.
7. Hardened the auto-publish chain in the v1.0.x point-release train: v1.0.1 (LiveView JS bundle fix), v1.0.2 (auto-merge Release Please PRs + `workflow_dispatch` step + `actions:write` permission), v1.0.3 (PAT-validated end-to-end publish chain). Codified a "quiet stable-line release posture" — `main` stays green, releases happen via Release Please PRs, not ad-hoc tagging.

### Audit

**No `/gsd:audit-milestone` ran for v1.0.** This is documented honestly rather than fabricated. Phase 21 ran a `verification` lane (`21-VERIFICATION.md` returned `gaps_found`); the gaps it enumerated (CR-01 resolved-history KeyError; CR-02 missing LiveView JS pipeline; release_gate not yet required on `main`) were all closed via plan 21-05 (pre-cut, commit `551ef05`), plan 21-06 (branch protection), and v1.0.1 (JS pipeline, commit `885e7d7`). The verification file itself was not re-run, but the closure is documented in 21-05/21-06 SUMMARY.md files and the shipped point releases.

### Known Gaps

- **No formal milestone audit** — the `/gsd:audit-milestone` step was skipped at v1.0 close (work proceeded directly into v1.1 Phase 23 on 2026-05-27). No `v1.0-MILESTONE-AUDIT.md` exists. Live evidence (HexDocs resolution, the `v1.0.0` tag, passing CI, the demo app smoke test) is the audit surrogate.
- **Plan 22-04 has no SUMMARY.md** — Task 2 was a `checkpoint:human-verify` blocking gate that was satisfied externally by the actual `v1.0.0` cut. Completion is provable via `git tag v1.0.0` and the live Hex package; the bookkeeping file was simply never written.
- **`21-VERIFICATION.md` reads `status: gaps_found`** — the file itself was not refreshed after 21-05/21-06 + v1.0.1 closed every gap. State is stale, not factual.
- **`.planning/REQUIREMENTS.md` for v1.0 was overwritten** by the v1.1 requirements drop on 2026-05-27 before `/gsd:complete-milestone` ran. The v1.0 REQUIREMENTS archive at `milestones/v1.0-REQUIREMENTS.md` is a retroactive reconstruction (provenance documented in that file) — recovered from commit `d482552` with completion checkboxes synchronized against per-phase SUMMARY.md evidence and v1.0.0–v1.0.3 git tags.
- **GOV-03 (`CODE_OF_CONDUCT.md`)** — intentionally omitted per user decision (content-filter issue). Not a gap, documented as a decision.
- **SLO state on `Application` env** — bandaged in v1.0.1 via `fa26ac2` (test isolation); the registry move off `Application.put_env` is the v1.2 graduation candidate before SLO-W1. Thread: `.planning/threads/slo-state-off-application-env.md`.

---

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
