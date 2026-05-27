# Roadmap: Parapet

## Milestones

- ✅ **v0.1 Trustworthy Spine** — shipped 2026-05-10 ([archive](milestones/v0.1-ROADMAP.md))
- ✅ **v0.2 Durable Spine & Operator UI** — shipped 2026-05-11 ([archive](milestones/v0.2-ROADMAP.md))
- ✅ **v0.3 Runbooks & Alert Routing** — shipped 2026-05-12 ([archive](milestones/v0.3-ROADMAP.md))
- ✅ **v0.4 Scoria AI Integration** — shipped 2026-05-15 ([archive](milestones/v0.4-ROADMAP.md))
- ✅ **v0.5 Proactive Resilience & Copilot Triage** — shipped 2026-05-16
- ✅ **v0.6 Change Correlation & Audit Trailing** — shipped 2026-05-17 ([archive](milestones/v0.6-ROADMAP.md))
- ✅ **v0.7 Async & Delivery Reliability** — shipped 2026-05-18
- ✅ **v0.8 Deterministic Escalation & Bounded Mitigation** — shipped 2026-05-19 ([archive](milestones/v0.8-ROADMAP.md))
- ✅ **v0.9 Performance, Scale & DX** — Phases 1-14 (shipped 2026-05-23) ([archive](milestones/v0.9-ROADMAP.md))
- ✅ **v0.10 Adopter Success** — Phases 15-18 (shipped 2026-05-24) ([archive](milestones/v0.10-ROADMAP.md))
- ✅ **v1.0 Stable Release** — Phases 19-22 (shipped 2026-05-26) ([archive](milestones/v1.0-ROADMAP.md))
- 🚧 **v1.1 Actionable Recovery** — Phases 23-29 (in progress; started 2026-05-27)
- 📌 **v1.2 Authoring DX & Maturity** — candidate; SLO-W1, Elixir/OTP matrix, supply-chain hardening, branch-protection enforcement

## Phases

<details>
<summary>✅ v0.10 Adopter Success (Phases 15-18) — SHIPPED 2026-05-24</summary>

Closed the gap between "feature-complete" and "adoptable by a stranger" on top of a feature-complete
v0.9 system — no new runtime deps, Ecto schemas, or Oban queues. Code deliverables landed before the
docs that name them. Full per-phase detail, success criteria, and closure evidence in
[milestones/v0.10-ROADMAP.md](milestones/v0.10-ROADMAP.md).

- [x] Phase 15: Packaging Credibility Gate (2/2 plans) — populated hex.pm metadata + `links:` + Release-Please-owned CHANGELOG + retroactive `docs/HISTORY.md`
- [x] Phase 16: SLO Starter Packs & Low-Traffic Guardrails (2/2 plans) — one-line `Parapet.SLO.StarterPack.WebSaaS`/`DeliverySaaS`, low-cardinality, low-traffic-safe
- [x] Phase 17: Recovery Depth — Runbook Templates (3/3 plans) — end-to-end `warning:` surface + 4 deepened + 3 new preview-first templates
- [x] Phase 18: Adoption & Authoring Docs (5/5 plans) — 7 adoption guides + `Parapet.Integration` behaviour (uniform, crash-proof `attach/1`)

</details>

<details>
<summary>✅ v0.9 Performance, Scale &amp; DX (Phases 1-14) — SHIPPED 2026-05-23</summary>

Core deliverables (Phases 1-5) plus closure & reconciliation phases (6-14). Full
detail and per-phase closure evidence in [milestones/v0.9-ROADMAP.md](milestones/v0.9-ROADMAP.md).

- [x] Phase 1: TSDB Cardinality Protection — `mix parapet.doctor cardinality` + compile-time label ceiling
- [x] Phase 2: Database Scale & Pruning — composite indexes, `Parapet.Evidence.Archiver`, `mix parapet.archive`
- [x] Phase 3: Operator UI Performance — bounded queue paging, 50k+ benchmark
- [x] Phase 4: Unified Install Path (DX) — `mix parapet.install` orchestrator + multi-node doctor checks (3 plans)
- [x] Phase 5: Multi-Node Safety Verification — Ecto-backed claims/circuit breakers under concurrency
- [x] Phase 6: Verify Cardinality Protection — Phase 1 closure proof
- [x] Phase 7: Close Operator UI Performance Proof — Phase 3 closure proof
- [x] Phase 8: Close Day-1 Install and Doctor Verification — Phase 4 closure proof
- [x] Phase 9: Reconcile Milestone Closure Artifacts
- [x] Phase 10: Tighten Archive Retention Semantics — resolved-only contract (2 plans)
- [x] Phase 11: Harden Multi-Node Proof Rerunnability — environment-conditional canary (3 plans)
- [x] Phase 12: Backfill Closure-Phase Verification Surfaces (4 plans)
- [x] Phase 13: Repair Generated Operator Resolve Flow (2 plans)
- [x] Phase 14: Backstop Generated Operator UI Closure Proof (2 plans)

</details>

<details>
<summary>✅ v1.0 Stable Release (Phases 19-22) — SHIPPED 2026-05-26</summary>

Froze Parapet's public API and telemetry contract under a written stability + deprecation policy, shipped the release-readiness scaffolding that lets a stranger trust `~> 1.0`, and cut `1.0.0` honestly through Release Please. Point releases `v1.0.1`–`v1.0.3` on 2026-05-27 hardened the auto-publish chain. Full per-phase detail, success criteria, and closure evidence in [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md).

- [x] Phase 19: API & Telemetry Freeze (4/4 plans) — three stability tiers, deprecation policy, telemetry contract test, `mix verify.public_api` gate, hard-deprecate `Parapet.SLO.define/2`
- [x] Phase 20: Governance & Docs Completeness (5/5 plans) — `CONTRIBUTING.md`/`SECURITY.md`, README semver + Elixir/OTP/Postgres matrix, four integration guides (Chimeway/Mailglass/Rindle/Scoria), Provider-as-bundle pattern, hexdocs grouping
- [x] Phase 21: Runnable Demo App (6/6 plans) — `examples/demo_app/` child Phoenix app with seeded evidence, smoke test, required `demo` CI gate, Hex-excluded
- [x] Phase 22: Release Readiness & 1.0 Cut (4/4 plans) — CI warnings-as-errors lane, Hex publish automation, proportionate verification gate, Release-Please `0.10.0 → 1.0.0` graduation; live `v1.0.0` tag and Hex/HexDocs resolution

**Release Evidence:** `v1.0.0` was published on 2026-05-26, `https://hex.pm/packages/parapet` and `https://hexdocs.pm/parapet/1.0.0/` resolve, and `main` returned to steady-state Release Please config with no one-off version pin.

</details>

### 🚧 v1.1 Actionable Recovery (In Progress — Started 2026-05-27)

**Milestone Goal:** Close the action loop the operator UI already implies. Turn runbook steps into executable, audited, host-registered recovery actions with a safe Preview → Confirm flow. Pure additive on the v1.0 frozen surface — most infrastructure already in `lib/`. Replace today's hand-off-to-Grafana-or-Notion pattern with one-click in-UI mitigations.

- [x] **Phase 23: Foundations — Telemetry Contract + `lease_until` Migration** — Lock the v1.1 telemetry event family under Experimental tier and add the claim-lease column before any capability ships (FND-01, FND-02) (completed 2026-05-27)
- [x] **Phase 24: Recovery Behaviour + Capability Allowlist** — `Parapet.Recovery` behaviour mirroring `Parapet.Integration`; widen `Parapet.Capabilities` allowlist by 2 atoms; crash-proof `attach/1` (RCV-01, RCV-02, RCV-03) (completed 2026-05-27)
- [ ] **Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX** — Close the operator-path-skips-claim defect; surface short-circuit/conflict return variants in the LiveView with operator-actionable next steps (UI-01, UI-02, UI-03, UI-04)
- [ ] **Phase 26: Audit Propagation** — TimelineEntry/ToolAudit writes for every Confirm; new `:recovery_failed` type for capability execution errors (AUD-01, AUD-02, AUD-03)
- [ ] **Phase 27: Prebuilt Playbooks** — Six runbook templates covering JTBD-MAP failure modes; two guidance-only by design, four capability-backed (PB-01, PB-02, PB-03, PB-04, PB-05, PB-06)
- [ ] **Phase 28: Demo Seed + CI Lane** — Demo app seeded with a Preview-able + Confirm-able incident; CI exercises happy-path, preview-expiry, short-circuit, and claim-conflict scenarios (DEMO-05, DEMO-06)
- [ ] **Phase 29: Stability + Adopter Onboarding** — Declare `Parapet.Recovery` Stable; CHANGELOG migration notes; `mix parapet.gen.recovery` Igniter task; `mix parapet.doctor` adoption signal; `docs/recovery-actions.md` adopter guide (STAB-07, ADOP-01, ADOP-02, ADOP-03)

### 📌 v1.2 Authoring DX & Maturity (Candidate)

**Candidate Goal:** Land additive DX and maturity work without reopening the 1.0 freeze.

- [ ] **SLO-W1** — Flag-based `mix parapet.gen.slo` Igniter task
- [ ] **Move `Parapet.SLO` registry off `Application` env** — graduation from the v1.0.1 grafana-test bandage
- [ ] **CI-M1** — Multi-version Elixir / OTP CI matrix
- [ ] **Post-1.0 maturity** — SHA-pinned actions, Dependabot, HexDocs logo/favicon, `MAINTAINING.md`, demo Docker Compose, branch-protection enforcement, conventional-commit taxonomy in CONTRIBUTING.md
- [ ] **v0.x → v1.0 migration guide + deployment guide**

## Phase Details

_Phase 19–22 (v1.0 Stable Release) details are archived — see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)._

### Phase 23: Foundations — Telemetry Contract + `lease_until` Migration

**Goal**: Lock the v1.1 telemetry event family under the Experimental stability tier and add the `lease_until` claim-lease column to `parapet_action_claims` before any capability code ships — both decisions are irreversible-on-publish under the v1.0 freeze, so they land first.
**Depends on**: Phase 22 (v1.0 stability machinery)
**Requirements**: FND-01, FND-02
**Complexity**: S (low-code, high-leverage; single coherent PR)
**Success Criteria** (what must be TRUE):

  1. Running `mix ecto.migrate` on a database that already has `parapet_action_claims` rows succeeds and backfills `lease_until` with a sensible default so no operator-claim ordering breaks.
  2. `docs/telemetry.md` enumerates the full `[:parapet, :operator, :recovery_action, ...]` event family under the Experimental stability tier — every event name, measurement key, and metadata key is explicit and distinguishable from the v1.0 frozen Stable telemetry.
  3. `ClaimService.claim_action/1` self-heals an expired-lease row atomically (`UPDATE ... WHERE lease_until < now() RETURNING *`), proven by a concurrency test that wins a claim against a stale claim left behind by a simulated node crash.
  4. A future capability addition can wire a new emit-site to a documented telemetry event without inventing a new event name.

**Plans**: 2 plans in 1 wave (single coherent PR per D-17)

  - [x] 23-01-PLAN.md — Telemetry contract module `Parapet.Telemetry.RecoveryAction` (Experimental tier) + contract test + docs/telemetry.md Recovery Action section + docs/stability.md Experimental row (FND-02) (Wave 1)
  - [x] 23-02-PLAN.md — `lease_until` migration + schema field + `ClaimService` self-heal + `concurrency_bootstrap.ex` DDL update + expired-lease self-heal concurrency test (FND-01) (Wave 1)

### Phase 24: Recovery Behaviour + Capability Allowlist

**Goal**: Ship the `Parapet.Recovery` behaviour (the host-app-facing capability registration API) and widen the `Parapet.Capabilities` allowlist by two atoms (`:revert_feature_flag`, `:disable_metric_label`) so every downstream phase has a stable public-API foundation to compile against.
**Depends on**: Phase 23 (telemetry contract + schema migration locked in)
**Requirements**: RCV-01, RCV-02, RCV-03
**Complexity**: M (new behaviour module + activation function + allowlist widening; mirrors `Parapet.Integration` pattern)
**Success Criteria** (what must be TRUE):

  1. A host application can declare a recovery action by writing a module with `use Parapet.Recovery` and implementing `id/0`, `label/0`, `preview/2`, `execute/2` — Dialyzer surfaces missing callbacks at compile time.
  2. Calling `Parapet.Recovery.attach([SomeMissingModule, RealModule])` registers `RealModule` and silently skips `SomeMissingModule` (the optional-dependency compile-out-cleanly contract holds).
  3. Attempting to register a capability id outside the 5-atom allowlist (`:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check`, `:revert_feature_flag`, `:disable_metric_label`) raises `ArgumentError` with a clear message naming the valid ids.
  4. 100 async tests registering distinct recovery modules into `Parapet.Capabilities` all pass without bleeding state (the v0.10 SLO Application-env mistake is not repeated — the new registry uses the existing supervised Agent).

**Plans**: 3 plans in 2 waves

  - [x] 24-01-PLAN.md — Behaviour module `Parapet.Recovery` at `lib/parapet/recovery.ex` (4 `@callback`s + minimal `__using__/1` + crash-proof `attach/1` with `Code.ensure_loaded?` skip + `{:ok, registered_ids}` return + verbatim Experimental admonition) (RCV-01, RCV-02) (Wave 1)
  - [x] 24-02-PLAN.md — Allowlist widening: append `:revert_feature_flag, :disable_metric_label` to `@valid_capabilities` in `lib/parapet/capabilities.ex` + add `Parapet.Recovery` row to `docs/stability.md` Experimental Modules table (alphabetical between `Parapet.MCP.PrometheusClient` and `Parapet.Telemetry.RecoveryAction`) (RCV-03) (Wave 1)
  - [x] 24-03-PLAN.md — `test/parapet/recovery_test.exs` sync sweep (all 4 success criteria via `attach/1` integration tests) + 100-async sweep parameterized cyclically over the 5 allowlisted atoms (Pitfall 13 avoidance) (RCV-01, RCV-02, RCV-03) (Wave 2 — depends on 24-01 + 24-02)

### Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX

**Goal**: Close the operator-path-skips-claim defect by routing `Parapet.Operator.confirm_runbook_step/4` through `Parapet.Automation.ClaimService.claim_action/1` (same path the Oban auto-execution uses), add the `{:short_circuited, reason}` and `{:conflicted, claim_id}` additive return variants, and render both branches in the LiveView with operator-actionable next steps. Preview tokens get a 5-minute expiry with `target_refs` hash gating.
**Depends on**: Phase 24 (behaviour module is the stable shape we wire against)
**Requirements**: UI-01, UI-02, UI-03, UI-04
**Complexity**: L (architectural defect closure spanning Operator API + ClaimService routing + generated LiveView template + idempotency-key lifecycle)
**Success Criteria** (what must be TRUE):

  1. Clicking "Preview" on a runbook step renders a panel showing action name, target args, blast-radius indicator, and the expected diff before any execution; clicking Confirm without a fresh Preview rejects the action with a clear "re-Preview required" message.
  2. A second operator clicking Confirm on the same step while the first operator's claim is in-flight sees a flash message "Another node is executing this recovery — refresh to see the outcome" (the `:conflicted` branch renders with operator-actionable next steps).
  3. Clicking Confirm on a Preview older than 5 minutes, or against an incident that resolved since Preview, returns `{:short_circuited, reason}` and the LiveView renders the reason ("Preview expired", "Incident already resolved") with a "Re-Preview" button.
  4. Every successful Confirm flows through `Parapet.Operator.ActionPayload` + `ClaimService.claim_action/1` with `action_kind: "operator"` — the same circuit-breaker and multi-node claim semantics the v0.8 escalation path uses, observable in a multi-node concurrency test.

**UI hint**: yes
**Plans**: TBD

### Phase 26: Audit Propagation

**Goal**: Every successful recovery action writes a `TimelineEntry` (`type: :recovery_confirmed`) AND a `ToolAudit` row capturing operator identity, action name, args, outcome, and timestamps. Add the `:recovery_failed` TimelineEntry type emitted on capability execution error — distinct from short-circuit/conflict states which write no entry because nothing executed.
**Depends on**: Phase 25 (Confirm path must be claim-protected before audit shape is finalized)
**Requirements**: AUD-01, AUD-02, AUD-03
**Complexity**: M (three-tier audit contract enforcement; new timeline entry type; dedup rules to keep timeline readable)
**Success Criteria** (what must be TRUE):

  1. Querying `TimelineEntry` after a successful Confirm returns a row with `type: :recovery_confirmed`, the operator's URN, the capability id, the resolved target args, outcome data, and accurate timestamps.
  2. Querying `ToolAudit` after the same Confirm returns a row with the matching operator identity, action name, args, outcome, and timestamps — the durable spine records what was done by whom, regardless of which surface (operator UI vs. automation) triggered it.
  3. A capability whose `execute/2` returns `{:error, reason}` produces a `TimelineEntry` with `type: :recovery_failed` capturing the error reason; short-circuit and conflict outcomes produce no TimelineEntry (telemetry-only) because nothing was actually executed.
  4. The retrospective generator surfaces recovery actions inline in the canonical chronology — not in a sidebar audit log.

**Plans**: TBD

### Phase 27: Prebuilt Playbooks

**Goal**: Ship six runbook templates covering JTBD-MAP failure modes. Two are guidance-only by design (Retry Storm, Suppression Drift — every obvious automated mitigation worsens the failure). Four are capability-backed (Stalled Async, Dead-Letter Drain, Deploy-Tied Incident, Cardinality Blowout) and exercise the claim-protected Confirm path.
**Depends on**: Phase 26 (audit propagation must work end-to-end before templates ship)
**Requirements**: PB-01, PB-02, PB-03, PB-04, PB-05, PB-06
**Complexity**: M (six EEx templates following established `priv/templates/parapet.gen.runbooks/` pattern; two reference existing capability ids, two reference new ones)
**Success Criteria** (what must be TRUE):

  1. An adopter running `mix parapet.gen.runbook retry_storm` (or any of the six templates) gets a host-owned runbook module that compiles cleanly under `if Code.ensure_loaded?(HostDep)`.
  2. The two guidance-only templates (Retry Storm, Suppression Drift) include explicit `warning:` blocks documenting why every obvious automated mitigation worsens the failure — adopters cannot accidentally wire a capability into them.
  3. The four capability-backed templates (Stalled Async via `:retry_async_item`, Dead-Letter Drain via `:requeue_dead_letter`, Deploy-Tied Incident via `:revert_feature_flag`, Cardinality Blowout via `:disable_metric_label`) demonstrate the Preview → Confirm flow against realistic preview output (count, target_refs, preconditions, warnings, summary).
  4. Adopters can map any of the six templates to a specific SLO or alert name using the existing `Parapet.Runbook` DSL without modification.

**Plans**: TBD

### Phase 28: Demo Seed + CI Lane

**Goal**: The demo app (`examples/demo_app/`) is seeded with at least one capability-backed incident demonstrating Preview → Confirm end-to-end on a fresh clone. CI exercises four scenarios (happy-path Confirm, preview-token-expired retry, short-circuit on resolved incident, claim-conflict between two simulated operators) so the loop is contract-tested.
**Depends on**: Phase 27 (templates exist to generate the demo's capability against)
**Requirements**: DEMO-05, DEMO-06
**Complexity**: M (extends the existing Phase 21 demo CI contract; new seeded incident; concurrency test for two-operator race)
**Success Criteria** (what must be TRUE):

  1. Running `cd examples/demo_app && mix setup && mix phx.server` on a fresh clone surfaces a seeded open incident with a Preview-able + Confirm-able runbook step; clicking through Preview → Confirm in the browser executes the capability against demo DB state.
  2. The CI demo lane runs four scenarios: happy-path Confirm produces TimelineEntry + ToolAudit; expired Preview token forces re-Preview; short-circuit branch fires when the incident is resolved between Preview and Confirm; claim-conflict resolves cleanly when two simulated operators race on Confirm.
  3. Any scenario failure breaks the `demo` CI job, which is wired into `release_gate` as a required check (continuing the v1.0 Phase 21 contract).
  4. The demo seed is replayable via `mix demo.reset` — adopters can run the recovery smoke test repeatedly without manual database cleanup.

**UI hint**: yes
**Plans**: TBD

### Phase 29: Stability + Adopter Onboarding

**Goal**: Declare `Parapet.Recovery` Stable in `docs/stability.md`; ship CHANGELOG migration notes for adopters who pattern-match `confirm_runbook_step/4` return values; ship `mix parapet.gen.recovery` Igniter task that scaffolds a custom capability module; add `mix parapet.doctor` recovery-action adoption signal; write `docs/recovery-actions.md` adopter guide. Closes the "shipped ≠ adopted" gap from the v0.10 LEARN-22-C lesson.
**Depends on**: Phase 28 (demo proves the loop end-to-end before docs name what shipped)
**Requirements**: STAB-07, ADOP-01, ADOP-02, ADOP-03
**Complexity**: M (combined stability declaration + Igniter task + doctor check + adopter guide; following the v0.10 Phase 18 "code lands before docs" pattern)
**Success Criteria** (what must be TRUE):

  1. `docs/stability.md` lists `Parapet.Recovery` and its 4 callbacks under the Stable tier; the CHANGELOG entry warns adopters who pattern-match `confirm_runbook_step/4` that the new `:short_circuited` and `:conflicted` error tuple variants are additive and will not be removed in 1.x.
  2. Running `mix parapet.gen.recovery RetryDLQ` scaffolds `lib/<host>/recovery/retry_dlq.ex` with the four required callbacks, a docstring template, and a unit test stub — flag-based, not interactive (matches the SLO-W1 idiom planned for v1.2).
  3. Running `mix parapet.doctor` reports a recovery-action adoption signal: count of attached capabilities, warnings for runbook steps that reference capabilities not in the registry, and per-capability check that the host module is loaded with the expected callbacks.
  4. `docs/recovery-actions.md` exists, explains capability authoring, Preview/Confirm UX, the error semantics (`:short_circuited`, `:conflicted`, `:recovery_failed`), and walks through four worked examples (one per capability-backed playbook); it is cross-linked from `docs/operator-ui.md` and `docs/getting-started.md`.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 15. Packaging Credibility Gate | v0.10 | 2/2 | Complete | 2026-05-24 |
| 16. SLO Starter Packs & Low-Traffic Guardrails | v0.10 | 2/2 | Complete | 2026-05-24 |
| 17. Recovery Depth — Runbook Templates | v0.10 | 3/3 | Complete | 2026-05-24 |
| 18. Adoption & Authoring Docs | v0.10 | 5/5 | Complete | 2026-05-24 |
| 23. Foundations — Telemetry Contract + `lease_until` Migration | v1.1 | 2/2 | Complete    | 2026-05-27 |
| 24. Recovery Behaviour + Capability Allowlist | v1.1 | 3/3 | Complete    | 2026-05-27 |
| 25. Wire Confirm Through ClaimService + Preview/Confirm UX | v1.1 | 0/0 | Not started | - |
| 26. Audit Propagation | v1.1 | 0/0 | Not started | - |
| 27. Prebuilt Playbooks | v1.1 | 0/0 | Not started | - |
| 28. Demo Seed + CI Lane | v1.1 | 0/0 | Not started | - |
| 29. Stability + Adopter Onboarding | v1.1 | 0/0 | Not started | - |

_Earlier milestone phases (1-22) are archived — see the milestone archives linked above._
