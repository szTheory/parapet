# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- [x] **v1.4 Trust Hardening & Host-App Compatibility** — Phases 37-39, 8 plans, shipped 2026-06-04. Archive: [v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- [x] **v1.5 Brand Book & Logo System** — Phases 40-43, 11 plans, shipped 2026-06-24. Archive: [v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- [x] **v1.6 Operator UI Brand & Design-System Audit** — Phases 44-50, 25 plans, shipped 2026-06-29. Archive: [v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)
- [x] **v1.7 Postgres Schema Isolation & Upgrade Path** — Phases 51-56, 21 plans, shipped 2026-07-02. Archive: [v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md)
- [ ] **v1.8 CI/CD Performance & DX** — Phases 57-60 (active)

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

### v1.8 CI/CD Performance & DX (Phases 57-60) — Active

- [x] **Phase 57: Test Suite Baseline** - Fix the two known-red tests and triage all `Process.sleep` calls so bare `mix test` is green (completed 2026-07-02)
- [x] **Phase 58: Local DX — mix ci & CONTRIBUTING** - Add the `mix ci` alias and `mix.exs` PLT-path config; update contributor docs (completed 2026-07-02)
- [x] **Phase 59: CI Caching, Lint-Once & release_gate Hardening** - PLT cache, lint-once job, `concurrency: cancel-in-progress`, hardened `release_gate`, SHA updates (completed 2026-07-02)
- [ ] **Phase 60: OTP Matrix Reshape & Nightly Schedule** - Trim PR matrix to 1 cell, full matrix on main+nightly, nightly schedule, D-11 retirement

## Phase Details

### Phase 57: Test Suite Baseline

**Goal**: A bare `mix test` exits green — the pre-existing reds are fixed directly and all `Process.sleep` call sites are correctly classified, so the "CI is the enforcement backstop" claim rests on an honest green suite.
**Depends on**: Nothing (first phase of v1.8; v1.7 shipped)
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05
**Success Criteria** (what must be TRUE):

  1. `mix test` (default env, default `parapet` prefix) exits 0 with no failures — `DocsPhase33Test` no longer asserts the stale `"make up-auto"` string
  2. `Telemetry.RecoveryActionTest` passes reliably under concurrent `async: true` runs — the `atom_count` delta check is removed while the `String.to_existing_atom/1`-raises guard is retained
  3. The three `Process.sleep` calls in `exemplar_telemetry_test.exs` are gone — telemetry dispatch is synchronous so no wait is needed
  4. The five intentional concurrency-simulation sleeps are annotated with a `@concurrency_hold_ms` module attribute and an explanatory comment, and the `executor_cluster_smoke_test.exs` startup-race sleep is replaced with a synchronous barrier
  5. A reusable `assert_eventually` / until helper exists in the test support layer so future async assertions have a deterministic alternative to `Process.sleep`

**Plans**: 2/2 plans complete

- [x] 57-01-PLAN.md — Fix the two red tests + delete the 3 spurious telemetry sleeps (TEST-01/02/03)
- [x] 57-02-PLAN.md — assert_eventually/2 helper, SELECT 1 startup barrier, 6 INTENTIONAL HOLD annotations + grep guard (TEST-04/05)

---

### Phase 58: Local DX — mix ci & CONTRIBUTING

**Goal**: Contributors can run a single `mix ci` command locally that mirrors the CI gate, and `CONTRIBUTING.md` tells them exactly what to run and what the known local-vs-CI deltas are.
**Depends on**: Phase 57 (green suite is a prerequisite for `mix ci` giving honest signal)
**Requirements**: DX-01, DX-02, DX-03
**Note**: This phase also adds `mix.exs` `dialyzer: [plt_file: {:no_warn, "priv/plts/project.plt"}]` and the `/priv/plts/` `.gitignore` entry, which are prerequisites for Phase 59's PLT cache wiring in CI.
**Success Criteria** (what must be TRUE):

  1. `mix ci` exists as a `mix.exs` alias and runs all 8 portable steps in fail-fast order (format, compile, compile --no-optional-deps, credo, hex.audit, dialyzer, test, verify.public_api)
  2. `CONTRIBUTING.md` instructs contributors to run `mix ci` before pushing and documents the three known local-vs-CI deltas (no `mix docs`, no operator UI diff, single `parapet` prefix only)
  3. The `lint-once` CI job calls `mix ci` for its portable subset, so `mix.exs` is the single source of truth and the local alias and CI cannot drift apart (DX-02 anti-drift guarantee)

**Plans**: 1/1 plans complete

- [x] 58-01-PLAN.md — `mix ci` alias + dialyzer PLT prereqs, `lint-once` CI job wiring, CONTRIBUTING.md rewrite + deltas

---

### Phase 59: CI Caching, Lint-Once & release_gate Hardening

**Goal**: The CI pipeline is structurally reshaped — Dialyzer PLT is cached, lint runs once on OTP 28, `release_gate` can never silently pass on an upstream failure, and the v1.7 dual-prefix false-green footgun is demonstrably intact.
**Depends on**: Phase 58 (PLT path in `mix.exs` + `mix ci` must exist before CI calls them)
**Requirements**: CI-01, CI-02, CI-03, CI-04, CI-05, CI-06
**INVARIANT**: The `test` job `_build` cache key retains `${{ matrix.schema_prefix }}` and every test matrix cell retains `mix compile --force`. No change in this phase may touch those two lines. Violation causes a false-green on the `public`-prefix schema leg.
**Success Criteria** (what must be TRUE):

  1. The Dialyzer PLT is cached at `priv/plts/` with a key of `plt-{os}-{otp}-{elixir}-{mix.lock hash}`; a PR that changes only test code does not rebuild the PLT from scratch
  2. A single `lint-once` job (OTP 28, no matrix) runs all quality steps exactly once; no quality step runs per-matrix-cell
  3. PR workflows cancel in-flight runs for the same PR on a new push (`concurrency: cancel-in-progress: true` for pull_request events); pushes to `main` are never cancelled
  4. `release_gate` has `if: always()` and an inline result-check script that exits 1 on any `failure` result — a failing upstream job can no longer cause `release_gate` to be silently skipped
  5. The `test` job `_build` cache key still includes `${{ matrix.schema_prefix }}` and `mix compile --force` is still present in every matrix cell (dual-prefix invariant preserved)
  6. `actions/checkout` and `erlef/setup-beam` are updated to current SHA-pinned releases across all workflow jobs

**Plans**: 2 plans
**Wave 1**

- [x] 59-01-PLAN.md — PLT cache in lint-once (CI-01/CI-02), top-level concurrency block (CI-03), release_gate hardening (CI-04); CI-05 invariant held

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 59-02-PLAN.md — SHA-pin refresh across all jobs to D-13 commits with version comments (CI-06); CI-05 invariant re-asserted

---

### Phase 60: OTP Matrix Reshape & Nightly Schedule

**Goal**: Pull requests get fast single-cell feedback, pushes to `main` and a nightly cron get full multi-OTP coverage across both schema-prefix legs, and EOL OTP 26 / Elixir 1.19 are retired from CI — with D-11 tech-debt flag formally closed.
**Depends on**: Phase 59 (lint-once job name and release_gate demo-skipped logic must be in place before the matrix-config job references them)
**Requirements**: MATRIX-01, MATRIX-02, MATRIX-03, MATRIX-04
**Success Criteria** (what must be TRUE):

  1. A pull-request CI run triggers exactly 1 test cell (OTP 28 · Elixir 1.20.2 · `parapet` prefix), giving contributors fast feedback without running the full matrix
  2. A push to `main` triggers the full 4-cell test matrix — OTP {27, 28, 29} × `parapet` + OTP 28 × `public` — on Elixir 1.20.2, retiring EOL OTP 26 and Elixir 1.19 from CI
  3. The `demo` smoke job is skipped on pull requests and runs on a single OTP-28 cell on main pushes and nightly, eliminating the redundant 3-OTP demo sweep
  4. A nightly scheduled workflow (`cron: '0 3 * * *'`) exercises the full test matrix plus demo, so full multi-version coverage runs even if no push lands that day; the D-11 tech-debt flag in `v1.7-MILESTONE-AUDIT.md` is retired with a dated note

**Plans**: 1/2 plans executed

- [x] 60-01-PLAN.md — ci.yml reshape: matrix-config resolver, schedule trigger, plain PR-skipped demo, release_gate truth-table hardening, event-scoped concurrency, EOL toolchain retirement (MATRIX-01/02/03/04)
- [ ] 60-02-PLAN.md — adjacent doc/toolchain edits: release-please pin bump, README CI sentence, CONTRIBUTING delta bullet, D-11 retirement (canonical PROJECT.md + dated pointers) (MATRIX-02/03)

## Progress Table

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 51. Prefix Core & Test Seam | v1.7 | 3/3 | Complete | 2026-06-30 |
| 52. Propagation Proof, Guards & CI Dual-Prefix Matrix | v1.7 | 4/4 | Complete | 2026-06-30 |
| 53. Generators & Library Migrations | v1.7 | 4/4 | Complete | 2026-07-01 |
| 54. Upgrade Path & Doctor | v1.7 | 4/4 | Complete | 2026-07-01 |
| 55. Demo App & Upgrade Docs | v1.7 | 2/2 | Complete | 2026-07-01 |
| 56. Contract & Release Hardening | v1.7 | 4/4 | Complete | 2026-07-02 |
| 57. Test Suite Baseline | v1.8 | 2/2 | Complete    | 2026-07-02 |
| 58. Local DX — mix ci & CONTRIBUTING | v1.8 | 1/1 | Complete    | 2026-07-02 |
| 59. CI Caching, Lint-Once & release_gate Hardening | v1.8 | 2/2 | Complete    | 2026-07-02 |
| 60. OTP Matrix Reshape & Nightly Schedule | v1.8 | 1/2 | In Progress|  |
