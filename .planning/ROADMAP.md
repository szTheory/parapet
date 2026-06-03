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
- ✅ **v1.1 Actionable Recovery** — shipped 2026-06-03 ([archive](milestones/v1.1-ROADMAP.md))
- 📌 **v1.2 Authoring DX & Maturity** — candidate; SLO-W1, Elixir/OTP matrix, supply-chain hardening, branch-protection enforcement

## Phases

<details>
<summary>✅ v1.1 Actionable Recovery (Phases 23-29) — SHIPPED 2026-06-03</summary>

Closed the action loop the operator UI already implies. Turn runbook steps into executable, audited, host-registered recovery actions with a safe Preview → Confirm flow. Pure additive on the v1.0 frozen surface. Full per-phase detail, success criteria, and closure evidence in [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md).

- [x] Phase 23: Foundations — Telemetry Contract + `lease_until` Migration (2/2 plans)
- [x] Phase 24: Recovery Behaviour + Capability Allowlist (3/3 plans)
- [x] Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX (3/3 plans)
- [x] Phase 26: Audit Propagation (1/1 plan)
- [x] Phase 27: Prebuilt Playbooks (1/1 plan)
- [x] Phase 28: Demo Seed + CI Lane (5/5 plans)
- [x] Phase 29: Stability + Adopter Onboarding (4/4 plans)

</details>


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

## Phase Details

_Phase 19–22 (v1.0 Stable Release) details are archived — see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)._

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 15. Packaging Credibility Gate | v0.10 | 2/2 | Complete | 2026-05-24 |
| 16. SLO Starter Packs & Low-Traffic Guardrails | v0.10 | 2/2 | Complete | 2026-05-24 |
| 17. Recovery Depth — Runbook Templates | v0.10 | 3/3 | Complete | 2026-05-24 |
| 18. Adoption & Authoring Docs | v0.10 | 5/5 | Complete | 2026-05-24 |
| 23. Foundations — Telemetry Contract + `lease_until` Migration | v1.1 | 2/2 | Complete    | 2026-05-27 |
| 24. Recovery Behaviour + Capability Allowlist | v1.1 | 3/3 | Complete    | 2026-05-27 |
| 25. Wire Confirm Through ClaimService + Preview/Confirm UX | v1.1 | 3/3 | Complete    | 2026-05-28 |
| 26. Audit Propagation | v1.1 | 1/1 | Complete    | 2026-05-28 |
| 27. Prebuilt Playbooks | v1.1 | 1/1 | Complete    | 2026-05-28 |
| 28. Demo Seed + CI Lane | v1.1 | 5/5 | Complete    | 2026-05-28 |
| 29. Stability + Adopter Onboarding | v1.1 | 4/4 | Complete    | 2026-05-29 |

_Earlier milestone phases (1-22) are archived — see the milestone archives linked above._

## Candidate Milestones

_Not-yet-started candidates. Kept after Phase Details so current-milestone tooling scopes correctly; also summarized in the top Milestones list._

### 📌 v1.2 Authoring DX & Maturity (Candidate)

**Candidate Goal:** Land additive DX and maturity work without reopening the 1.0 freeze.

- [ ] **SLO-W1** — Flag-based `mix parapet.gen.slo` Igniter task
- [ ] **Move `Parapet.SLO` registry off `Application` env** — graduation from the v1.0.1 grafana-test bandage
- [ ] **CI-M1** — Multi-version Elixir / OTP CI matrix
- [ ] **Post-1.0 maturity** — SHA-pinned actions, Dependabot, HexDocs logo/favicon, `MAINTAINING.md`, demo Docker Compose, branch-protection enforcement, conventional-commit taxonomy in CONTRIBUTING.md
- [ ] **v0.x → v1.0 migration guide + deployment guide**
