# Requirements: Parapet — v1.1 Actionable Recovery

**Defined:** 2026-05-27
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Milestone posture:** Close the action loop the operator UI already implies. Turn runbook steps into executable, audited, host-registered recovery actions with a safe Preview → Confirm flow. Pure additive on the v1.0 frozen surface — most infrastructure already in `lib/`. Research backing: `.planning/research/SUMMARY.md`.

## v1.1 Requirements

24 requirements across 8 categories. Each maps to exactly one roadmap phase. Continuing phase numbering from v1.0 (last phase = 22), so v1.1 starts at phase 23.

### Foundations (FND)

Schema + telemetry contract changes that must land BEFORE any capability dispatch code (lock-in cost is higher to change later).

- [ ] **FND-01**: `parapet_action_claims` schema migration adds a `lease_until` column for claim lease/expiry; existing rows backfilled with a sensible default so no operator-claim ordering breaks.
- [ ] **FND-02**: Telemetry contract for `[:parapet, :operator, :recovery_action, ...]` events is documented in `docs/telemetry.md` under the Experimental stability tier (separate from v1.0's frozen Stable telemetry); event names, measurement keys, and metadata keys are explicit.

### Recovery Behaviour (RCV)

The host-app-facing capability registration API.

- [ ] **RCV-01**: Host application can declare named recovery actions via a `Parapet.Recovery` behaviour mirroring `Parapet.Integration` (callbacks: `id/0`, `label/0`, `preview/2`, `execute/2`); written code follows the proven uniform-activation idiom.
- [ ] **RCV-02**: `Parapet.Recovery.attach/1` is uniform and crash-proof — silently skips unloaded host modules via `Code.ensure_loaded?/1` so optional capabilities compile out cleanly when their host deps aren't present.
- [ ] **RCV-03**: `Parapet.Capabilities` allowlist widened from 3 to 5 atoms (adds `:revert_feature_flag`, `:disable_metric_label`); other capability ids attempted at attach time are rejected with a clear error.

### Preview → Confirm Flow (UI)

The operator-facing experience.

- [ ] **UI-01**: Operator clicks "Preview" on a runbook step → sees action name, target args, blast-radius indicator, and expected diff in a dedicated panel before any execution.
- [ ] **UI-02**: Operator's Confirm click routes execution through `Parapet.Operator.ActionPayload` + `Parapet.Automation.ClaimService.claim_action/1` (closes the existing defect where operator-clicked path skipped the claim service that the Oban auto-execution path uses).
- [ ] **UI-03**: Preview tokens have a 5-minute expiry; stale previews are detected via `target_refs` hash and rejected with a clear error message; expired tokens prompt the operator to re-Preview.
- [ ] **UI-04**: Confirm returns `{:short_circuited, reason}` if circuit breaker open or incident state changed since Preview, and `{:conflicted, claim_id}` if another operator holds the claim; the LiveView renders both branches with operator-actionable next steps.

### Audit Propagation (AUD)

Evidence trail for every action.

- [ ] **AUD-01**: Every successful recovery action emits a `TimelineEntry` (`type: :recovery_confirmed`) linked to the incident, capturing operator identity, action name, args, outcome, and timestamps.
- [ ] **AUD-02**: Every successful recovery action emits a `ToolAudit` row with the same evidence — operator identity, action name, args, outcome, timestamps — so the durable spine records what was done by whom.
- [ ] **AUD-03**: `:recovery_failed` TimelineEntry type is added and emitted on capability execution error (distinct from short-circuit / conflict states, which emit no entry because nothing was executed).

### Prebuilt Playbooks (PB)

Six runbooks shipping with v1.1, matching JTBD-MAP failure modes.

- [ ] **PB-01**: Retry Storm runbook ships as guidance-only by design (no capability binding) — every obvious mitigation worsens the failure; the template includes an explicit warning explaining why.
- [ ] **PB-02**: Suppression Drift runbook ships as guidance-only by design (no capability binding) — same architectural rationale documented inline.
- [ ] **PB-03**: Stalled Async runbook ships with a capability-backed step via the existing `:retry_async_item` allowlist id; demo scenario validates Preview → Confirm against a seeded stalled job.
- [ ] **PB-04**: Dead-Letter Drain runbook ships with a capability-backed step via the existing `:requeue_dead_letter` allowlist id; demo scenario validates Preview → Confirm against seeded DLQ entries.
- [ ] **PB-05**: Deploy-Tied Incident runbook ships with a capability-backed step via the new `:revert_feature_flag` capability id; example host implementation uses Rulestead as the canonical wiring target.
- [ ] **PB-06**: Cardinality Blowout runbook ships with a capability-backed step via the new `:disable_metric_label` capability id; example host implementation references the existing cardinality analyzer surface.

### Demo Seed (DEMO)

Demo app proves the loop end-to-end.

- [ ] **DEMO-05**: Demo app (`examples/demo_app/`) is seeded with at least one capability-backed incident that exposes a Preview-able + Confirm-able action via the generated operator UI; the seed runs as part of `mix setup` so fresh clones demonstrate the loop on first open.
- [ ] **DEMO-06**: CI demo lane exercises four scenarios on the demo: happy-path Confirm, Preview-token-expired retry, short-circuit on resolved incident, and claim-conflict between two simulated operators; failures break the build.

### Stability (STAB)

The v1.1 surface joins the v1.0 contract.

- [ ] **STAB-07**: `Parapet.Recovery` behaviour and its 4 callbacks are declared Stable in `docs/stability.md`; CHANGELOG migration notes warn adopters who pattern-match `Parapet.Operator.confirm_runbook_step/4` return values that the new error tuple variants (`:short_circuited`, `:conflicted`) are additive and will not be removed in 1.x.

### Adopter Onboarding (ADOP)

The "shipped ≠ adopted" prevention.

- [ ] **ADOP-01**: `mix parapet.gen.recovery <NAME>` Igniter task scaffolds a new host-application recovery module with the four required callbacks and a docstring template; flag-based, not interactive (matches the SLO-W1 idiom planned for v1.2).
- [ ] **ADOP-02**: `mix parapet.doctor` reports a recovery-action adoption signal — count of attached capabilities, warnings for runbook steps that reference capabilities not in the registry, and per-capability check that the host module is loaded and has the expected callbacks.
- [ ] **ADOP-03**: `docs/recovery-actions.md` adopter guide explains capability authoring, Preview/Confirm UX, error semantics, and four worked examples (one per capability-backed playbook); cross-linked from the existing operator-ui.md and getting-started.md.

## Future Requirements

Deferred to v1.2+ — not in v1.1 scope:

- **Move `Parapet.SLO` registry off `Application` env** — graduation from the v1.0.1 grafana-test bandage. See `.planning/threads/slo-state-off-application-env.md`. Lands FIRST in v1.2 so SLO-W1 inherits clean state. (The new `Parapet.Recovery` registry uses the existing `Parapet.Capabilities` Agent, NOT `Application.put_env`, so v1.1 doesn't repeat the mistake.)
- **`mix parapet.gen.slo`** — flag-based Igniter task. Design decision settled in `prompts/V1-SLO-WIZARD-BUNDLES.md`. v1.2.
- **Elixir/OTP CI matrix + Dependabot + SHA-pinned actions + `MAINTAINING.md`** — supply-chain hardening. v1.2.
- **Conventional-commit taxonomy codified in `CONTRIBUTING.md` + PR template + path-based branch protection rulesets.** v1.2.
- **v0.x → v1.0 migration guide + deployment guide.** v1.2.
- **MCP Preview surface (read-only) for recovery actions.** Stability-tier mismatch with the rest of MCP; defer until MCP graduates to Stable. v1.3+.
- **Per-capability cooldown / breaker scope (vs the system-scoped breaker today).** Defer; current scope works for v1.1. v1.2.
- **Responder model, handoff, on-call rotation hooks (PagerDuty/Opsgenie).** Team Workflow & Coordination, JTBD #2. v1.3.
- **Multi-app journey correlation + vertical starter packs.** JTBD #4. v1.4+.

## Out of Scope

Explicitly excluded from v1.1 to prevent scope creep. Documented so future sessions can't relitigate.

| Feature | Reason |
|---------|--------|
| Autonomous (no-human) recovery action execution | Operator-in-the-loop is the safety posture parapet sells. Auto-execution-via-Oban exists for *escalation policies* (which are configured ahead of time), not ad-hoc operator-initiated actions. Servers reject `ActionPayload` records whose `actor` field starts with `system:` on the human-Confirm path. |
| Cross-app journey correlation | parapet stays single-app for v1.1. Multi-app correlation is JTBD #4, parked for v1.4+. v1.1 design must not lock in single-app-only schema decisions, but also must not implement multi-app. |
| Multi-tenant action scoping (per-customer / per-org) | Single-tenant SaaS focus for v1.1. Deferred to v1.4+ alongside multi-tenant SLO scoping. v1.1 must not add `tenant_id` columns. |
| Capability dispatch via Oban for long-running actions | All v1.1 capabilities execute synchronously inside the LiveView Confirm handler. If a capability needs to run async, that's a future capability flag, not a v1.1 surface. Defer until a real long-running playbook appears. |
| Capability marketplaces / capability discovery from Hex | parapet is host-owned. Capabilities are declared in the host app, attached at boot, and registered into `Parapet.Capabilities`. No remote registry. |
| `Parapet.SLO.Provider` redesign or removal of `Parapet.SLO.define/2` | v1.0 already hard-deprecated `define/2`. Removal happens at v2.0. v1.1 does not touch the SLO surface. |

## Previously Validated

The v1.0 requirements (25 total: STAB-01 through STAB-06, GOV-01 through GOV-05, DOCS-01 through DOCS-06, DEMO-01 through DEMO-04, REL-01 through REL-04) shipped in milestone v1.0 on 2026-05-26. All marked complete; see git history under phases 19–22 and `.planning/MILESTONES.md` for the validation record. v1.1 numbering continues from there (DEMO continues at DEMO-05; STAB continues at STAB-07).

## Traceability

Filled by the roadmapper. Each v1.1 requirement maps to exactly one phase (23–29).

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 | Phase 23 | Pending |
| FND-02 | Phase 23 | Pending |
| RCV-01 | Phase 24 | Pending |
| RCV-02 | Phase 24 | Pending |
| RCV-03 | Phase 24 | Pending |
| UI-01 | Phase 25 | Pending |
| UI-02 | Phase 25 | Pending |
| UI-03 | Phase 25 | Pending |
| UI-04 | Phase 25 | Pending |
| AUD-01 | Phase 26 | Pending |
| AUD-02 | Phase 26 | Pending |
| AUD-03 | Phase 26 | Pending |
| PB-01 | Phase 27 | Pending |
| PB-02 | Phase 27 | Pending |
| PB-03 | Phase 27 | Pending |
| PB-04 | Phase 27 | Pending |
| PB-05 | Phase 27 | Pending |
| PB-06 | Phase 27 | Pending |
| DEMO-05 | Phase 28 | Pending |
| DEMO-06 | Phase 28 | Pending |
| STAB-07 | Phase 29 | Pending |
| ADOP-01 | Phase 29 | Pending |
| ADOP-02 | Phase 29 | Pending |
| ADOP-03 | Phase 29 | Pending |

**Coverage:**

- v1.1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 — v1.1 traceability filled (Phases 23–29, 24/24 mapped)*
