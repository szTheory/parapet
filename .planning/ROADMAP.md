# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- [x] **v1.4 Trust Hardening & Host-App Compatibility** — Phases 37-39, 8 plans, shipped 2026-06-04. Archive: [v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- [x] **v1.5 Brand Book & Logo System** — Phases 40-43, 11 plans, shipped 2026-06-24. Archive: [v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- [x] **v1.6 Operator UI Brand & Design-System Audit** — Phases 44-50, 25 plans, shipped 2026-06-29. Archive: [v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)
- [x] **v1.7 Postgres Schema Isolation & Upgrade Path** — Phases 51-56, 21 plans, shipped 2026-07-02. Archive: [v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md)

## Phases

<details>
<summary>✅ v1.5 Brand Book & Logo System (Phases 40-43) — SHIPPED 2026-06-24</summary>

- [x] Phase 40: Brand Pressure-Test & Critique Gate (1/1 plans) — completed 2026-06-23
- [x] Phase 41: Logo Exploration & User Selection Gate (6/6 rounds) — completed 2026-06-24
- [x] Phase 42: Token System & HTML Brand Book (3/3 plans) — completed 2026-06-24
- [x] Phase 43: Collateral, Wiring & QA/Audit Gate (3/3 plans) — completed 2026-06-24

Full detail: [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)

</details>

<details>
<summary>✅ v1.6 Operator UI Brand & Design-System Audit (Phases 44-50) — SHIPPED 2026-06-29</summary>

- [x] Phase 44: Foundations — token re-skin, fonts & audit apparatus (4/4 plans) — completed 2026-06-25
- [x] Phase 45: Primitive components (4/4 plans) — completed 2026-06-25
- [x] Phase 46: Navigation, shell & data-display (4/4 plans) — completed 2026-06-26
- [x] Phase 47: Component groups / meta-components (3/3 plans) — completed 2026-06-26
- [x] Phase 48: Pages, flows & microcopy (4/4 plans) — completed 2026-06-28
- [x] Phase 49: Stress fixtures & seed coverage (3/3 plans) — completed 2026-06-28
- [x] Phase 50: Guardrails, parity & idempotence gate (3/3 plans) — completed 2026-06-28

Full detail: [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)

</details>

<details>
<summary>✅ v1.7 Postgres Schema Isolation & Upgrade Path (Phases 51-56) — SHIPPED 2026-07-02</summary>

Parapet's six spine tables live in a dedicated, configurable `parapet` Postgres schema by default (compile-time `@schema_prefix`, no runtime `prefix:`); existing adopters get a documented, tested, opt-in upgrade path (stay-on-`public` or a reversible `SET SCHEMA` move); public API + telemetry contracts stay provably frozen. Closes the audited #1 quality weakness. 29/29 requirements, audit `tech_debt` (zero blockers).

- [x] Phase 51: Prefix Core & Test Seam (3/3 plans) — completed 2026-06-30
- [x] Phase 52: Propagation Proof, Guards & CI Dual-Prefix Matrix (4/4 plans) — completed 2026-06-30
- [x] Phase 53: Generators & Library Migrations (4/4 plans) — completed 2026-07-01
- [x] Phase 54: Upgrade Path & Doctor (4/4 plans) — completed 2026-07-01
- [x] Phase 55: Demo App & Upgrade Docs (2/2 plans) — completed 2026-07-01
- [x] Phase 56: Contract & Release Hardening (4/4 plans) — completed 2026-07-02

Full detail: [milestones/v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md) · Audit: [milestones/v1.7-MILESTONE-AUDIT.md](milestones/v1.7-MILESTONE-AUDIT.md)

</details>

## Next Milestone

The approved v1.7→v1.9 roadmap continues (define with `/gsd-new-milestone`):

- **v1.8 CI/CD performance & DX** — Dialyzer PLT caching, `concurrency: cancel-in-progress`, lint-once, `mix ci` alias, `Process.sleep` removal, 3-OTP matrix → main+nightly (CI-01). Note: v1.7's dual-prefix matrix interacts with this pipeline reshape — sequence accordingly.
- **v1.9 Quality hardening** — telemetry drift gate `telemetry_stable.json` (TELEM-01), decompose the `operator.ex` god-module behind the frozen Stable surface (REFACTOR-01), Playwright + axe-core a11y lane and ExUnit-pin the v1.6 `override_closeout` gaps (A11Y-01). Also fold in the v1.7 tech-debt item #6 (quarantine pre-existing `DocsPhase33Test` + `Telemetry.RecoveryActionTest` reds).

## Progress Table

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 51. Prefix Core & Test Seam | v1.7 | 3/3 | Complete | 2026-06-30 |
| 52. Propagation Proof, Guards & CI Dual-Prefix Matrix | v1.7 | 4/4 | Complete | 2026-06-30 |
| 53. Generators & Library Migrations | v1.7 | 4/4 | Complete | 2026-07-01 |
| 54. Upgrade Path & Doctor | v1.7 | 4/4 | Complete | 2026-07-01 |
| 55. Demo App & Upgrade Docs | v1.7 | 2/2 | Complete | 2026-07-01 |
| 56. Contract & Release Hardening | v1.7 | 4/4 | Complete | 2026-07-02 |
