---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: CI/CD Performance & DX
current_phase: 59
current_phase_name: CI Caching, Lint-Once & release_gate Hardening
status: executing
stopped_at: Phase 59 context gathered (assumptions mode)
last_updated: "2026-07-02T22:54:14.505Z"
last_activity: 2026-07-02
last_activity_desc: Phase 58 complete, transitioned to Phase 59
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 3
  completed_plans: 3
  percent: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-02 after v1.7 milestone)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Phase 58 — local-dx-mix-ci-contributing

## Current Position

Phase: 59 — CI Caching, Lint-Once & release_gate Hardening
Plan: Not started
Status: Ready to execute
Last activity: 2026-07-02 — Phase 58 complete, transitioned to Phase 59

```
v1.8 Progress: [█████░░░░░░░░░░░░░░░░] 25% (1/4 phases)
```

## Milestone Roadmap (v1.8)

Phases continue from v1.7 (ended Phase 56). Dependency chain: green suite first (Phase 57), then local DX + PLT path prereqs (Phase 58), then CI structural reshape (Phase 59), then matrix/triggers (Phase 60).

- [x] **57 Test Suite Baseline** — TEST-01..05 ✓ (2026-07-02)
- [ ] **58 Local DX — mix ci & CONTRIBUTING** — DX-01..03
- [ ] **59 CI Caching, Lint-Once & release_gate Hardening** — CI-01..06
- [ ] **60 OTP Matrix Reshape & Nightly Schedule** — MATRIX-01..04

## Performance Metrics

**Velocity:**

- Total plans completed (this milestone): 0
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 57 | 2 | - | - |
| 58 | 1 | - | - |
| 59 | TBD | - | - |
| 60 | TBD | - | - |

**Recent Trend (v1.7 reference):**

| Phase 51 P01 | 6min | - tasks | - files |
| Phase 51 P02 | 4min | 3 tasks | 6 files |
| Phase 51 P03 | 4min | 3 tasks | 1 files |
| Phase 52 P01 | 12 | 3 tasks | 7 files |
| Phase 52 P02 | 2 | 1 tasks | 1 files |
| Phase 52 P03 | 6 minutes | 2 tasks | 3 files |
| Phase 52 P04 | 10 | 2 tasks | 2 files |
| Phase 54 P01 | 4 | 2 tasks | 2 files |
| Phase 54 P02 | 9 | 3 tasks | 6 files |
| Phase 54 P04 | 300 | - tasks | - files |
| Phase 54 P04 | 434 | 2 tasks | 2 files |
| Phase 54 P03 | 3 | 1 tasks | 1 files |
| Phase 55-demo-app-upgrade-docs P01 | 7 | 3 tasks | 4 files |
| Phase 55-demo-app-upgrade-docs P02 | 6 | 3 tasks | 5 files |
| Phase 56 P01 | 3 | 2 tasks | 2 files |
| Phase 56 P02 | 4 | 1 tasks | 1 files |
| Phase 56 P03 | 5 | 2 tasks | 1 files |
| Phase 56 P04 | 10 | 2 tasks | 2 files |
| Phase 57 P01 | 3 | 2 tasks | 3 files |
| Phase 57 P02 | 5 | 4 tasks | 7 files |

## Accumulated Context

### Decisions

**v1.8 resolved decision points (locked — do not re-open):**

- DP-1: CI tests Elixir 1.20.2 · OTP {27, 28, 29}. Drop EOL OTP 26 and Elixir 1.19 from CI. `mix.exs` stays `~> 1.19` (no library floor change — VER-01 deferred to v1.9+).
- DP-2: Fix the two red tests directly — `DocsPhase33Test` (1-line assertion update) and `Telemetry.RecoveryActionTest` (13-line deletion of atom_count delta check). No quarantine infra.
- DP-3: Trim `demo` job to a single OTP-28 leg; skip on PRs; run on main + nightly only.
- DP-4: Drop the cross-OTP `compile-matrix` job for v1.8. Revisit in v1.9 if an OTP-specific warning is missed.

**Non-negotiable invariants (applies to every v1.8 phase):**

- `${{ matrix.schema_prefix }}` MUST stay in the `test` job `_build` cache key — removing it causes a false-green on the `public`-prefix leg (v1.7 dual-prefix proof would be broken)
- `mix compile --force` MUST stay in every test matrix cell — belt-and-suspenders for the compile-time `@schema_prefix`
- `release_gate` job name MUST NOT be renamed — branch protection references it by name
- Public API, telemetry contracts, and host-ownership model are frozen — v1.8 is DX/pipeline only

**v1.7 carry-forward decisions (still active):**
Config key is `:schema_prefix` (never bare `:prefix`). Mechanism is compile-time `@schema_prefix`. No `search_path` switching. Existing adopters opt-in only.

- [Phase ?]: TEST-01/TEST-02: Delete stale doc-drift assertions and atom-count delta block directly — no quarantine infrastructure
- [Phase ?]: TEST-03: Remove three dead-time Process.sleep(10) calls from exemplar_telemetry_test.exs — :telemetry.execute/3 dispatches synchronously
- [Phase ?]: D-12/TEST-05: assert_eventually/2 plain def on ConcurrencyCase — re-raises real ExUnit.AssertionError verbatim on timeout, catches ONLY ExUnit.AssertionError
- [Phase ?]: D-07/D-08/TEST-04: SELECT 1 readiness barrier replaces Process.sleep(200) — self-referential anon fn, 5_000ms deadline, raises DX message on expiry
- [Phase ?]: D-09/D-10/D-11/TEST-04: per-file @concurrency_hold_ms (75x4, 50x1) + INTENTIONAL HOLD: two-line annotation on all 6 hold sites
- [Phase ?]: D-17: check_intentional_hold.sh standalone grep guard (not wired to CI); promotion to Credo check deferred to Phase 58/59

### Pending Todos

None.

### Blockers/Concerns

None at roadmap creation. Key risks to monitor during planning:

- PLT `plt_file:` path in `mix.exs` must exactly match the `priv/plts` cache path in `ci.yml` — mismatch silently defeats the PLT cache (Phase 59 risk).
- OTP 29 transitive dep compatibility — OTP 29 released 7 weeks before research date; verify `mix deps.get` succeeds against OTP 29 at Phase 60 start.
- Action SHA currency — `actions/checkout` and `erlef/setup-beam` SHAs may have advanced since research (2026-07-02); re-verify at Phase 59 implementation time.

## Deferred Items

Items acknowledged and deferred at v1.6 milestone close on 2026-06-29 (`override_closeout`):

| Category | Item | Status |
|----------|------|--------|
| uat_gap | phase-44 44-UAT.md (TOKEN-04 manual visual check) | testing — 1 pending scenario |
| verification_gap | phase-44 44-VERIFICATION.md (TOKEN-04 layout-shift, manual-only) | human_needed |
| verification_gap | phase-48 no 48-VERIFICATION.md (never ran /gsd-verify-work) | covered by milestone audit (Nyquist phase-48 compliant) |

All three trace to requirements that shipped and were human-verified in the live UI; the gap is in automated (ExUnit) coverage. v1.9 A11Y-01 is slated to ExUnit-pin them. See MILESTONES.md v1.6 → Known Gaps.

## Session Continuity

Last session: 2026-07-02T22:39:58.175Z
Stopped at: Phase 59 context gathered (assumptions mode)
Resume file: .planning/phases/59-ci-caching-lint-once-release-gate-hardening/59-CONTEXT.md
Next step: `/gsd-discuss-phase 58` — Local DX — mix ci & CONTRIBUTING (no CONTEXT.md yet)

## Operator Next Steps

- Plan Phase 57 with `/gsd-plan-phase 57`
