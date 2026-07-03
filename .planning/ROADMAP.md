# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- [x] **v1.4 Trust Hardening & Host-App Compatibility** — Phases 37-39, 8 plans, shipped 2026-06-04. Archive: [v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- [x] **v1.5 Brand Book & Logo System** — Phases 40-43, 11 plans, shipped 2026-06-24. Archive: [v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- [x] **v1.6 Operator UI Brand & Design-System Audit** — Phases 44-50, 25 plans, shipped 2026-06-29. Archive: [v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)
- [x] **v1.7 Postgres Schema Isolation & Upgrade Path** — Phases 51-56, 21 plans, shipped 2026-07-02. Archive: [v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md)
- [x] **v1.8 CI/CD Performance & DX** — Phases 57-60, 7 plans, shipped 2026-07-03. Archive: [v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md)
- [ ] **v1.9 Quality Hardening** — not yet defined (`/gsd-new-milestone`)

## Phases

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

<details>
<summary>✅ v1.8 CI/CD Performance & DX (Phases 57-60) — SHIPPED 2026-07-03</summary>

Reshaped the CI pipeline to be fast, cheap, and green-by-default with zero public-API/telemetry change: bare `mix test` is honestly green (two pre-existing reds fixed directly, closing v1.7 tech-debt #6), the Dialyzer PLT is cached, quality runs once in a single OTP-28 `lint-once` job, PRs run one cell while `main` + a nightly cron carry the full OTP {27,28,29} × dual-prefix matrix, `release_gate` is hardened, and a `mix ci` alias mirrors the gate locally. 18/18 requirements; verified closeout (artifact audit clear, all phases `passed`).

- [x] Phase 57: Test Suite Baseline (2/2 plans) — completed 2026-07-02
- [x] Phase 58: Local DX — mix ci & CONTRIBUTING (1/1 plan) — completed 2026-07-02
- [x] Phase 59: CI Caching, Lint-Once & release_gate Hardening (2/2 plans) — completed 2026-07-02
- [x] Phase 60: OTP Matrix Reshape & Nightly Schedule (2/2 plans) — completed 2026-07-03

Full detail: [milestones/v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md)

</details>

### 🔜 v1.9 Quality Hardening (Planned)

Not yet defined. Run `/gsd-new-milestone` to scope. Carried-forward candidates: **TELEM-01** (stable telemetry manifest + drift gate), **REFACTOR-01** (decompose the `operator.ex` god-module behind the frozen Stable surface), **A11Y-01** (Playwright + axe-core a11y lane; ExUnit-pin the v1.6 `override_closeout` gaps), and **VER-01** (bump `mix.exs` Elixir floor `~> 1.19` → `~> 1.20`, later).

## Progress Table

| Milestone | Phases | Plans | Status | Shipped |
|-----------|--------|-------|--------|---------|
| v1.6 Operator UI Brand & Design-System Audit | 44-50 | 25/25 | Shipped | 2026-06-29 |
| v1.7 Postgres Schema Isolation & Upgrade Path | 51-56 | 21/21 | Shipped | 2026-07-02 |
| v1.8 CI/CD Performance & DX | 57-60 | 7/7 | Shipped | 2026-07-03 |
| v1.9 Quality Hardening | TBD | 0/0 | Not started | — |
