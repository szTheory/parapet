---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Postgres Schema Isolation & Upgrade Path
current_phase: 52
current_phase_name: Propagation Proof, Guards & CI Dual-Prefix Matrix
status: verifying
stopped_at: Completed 51-03-PLAN.md
last_updated: "2026-06-30T04:47:31.979Z"
last_activity: 2026-06-30
last_activity_desc: Phase 51 complete, transitioned to Phase 52
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 17
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-29 after starting milestone v1.7 Postgres Schema Isolation & Upgrade Path)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Phase 51 — prefix-core-test-seam

## Current Position

Phase: 52 — Propagation Proof, Guards & CI Dual-Prefix Matrix
Plan: Not started
Status: Phase complete — ready for verification
Last activity: 2026-06-30 — Phase 51 complete, transitioned to Phase 52

Progress: [░░░░░░░░░░] 0%

## Milestone Roadmap (v1.7)

Continuing phase numbering from v1.6 (ended at Phase 50). Hard dependency chain: the config seam + bootstrap qualification (Phase 51) must land before propagation/guards can run under the prefix; the dual-prefix CI matrix (Phase 52) is the honest proof; generators → upgrade path+doctor → demo+docs → release hardening follow.

- [ ] **51 Prefix Core & Test Seam** — PREFIX-01..04, TEST-01, TEST-02
- [ ] **52 Propagation Proof, Guards & CI Dual-Prefix Matrix** — PROP-01..03, TEST-03
- [ ] **53 Generators & Library Migrations** — GEN-01..07
- [ ] **54 Upgrade Path & Doctor** — UPG-01..05, DOCTOR-01
- [ ] **55 Demo App & Upgrade Docs** — DOC-01, DOC-02, SAFE-03
- [ ] **56 Contract & Release Hardening** — SAFE-01, SAFE-02, SAFE-04

## Performance Metrics

**Velocity:**

- Total plans completed (this milestone): 0
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 51 | 3 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 51 P01 | 6min | - tasks | - files |
| Phase 51 P02 | 4min | 3 tasks | 6 files |
| Phase 51 P03 | 4min | 3 tasks | 1 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. v1.7 locked design decisions (see `.planning/research/v1.7/00-SYNTHESIS.md` §1):

- Config key is `:schema_prefix` (never bare `:prefix` — collides with frozen telemetry "event prefix"); default `"parapet"`; `nil`/`""`/`"public"` ⇒ unprefixed.
- Mechanism is compile-time `@schema_prefix` via a shared `use Parapet.Spine.Schema` macro; runtime `prefix:` is BANNED (split-brain) and enforced by a static guard test.
- No `search_path` switching (keeps `public`-resident extensions resolving).
- Existing adopters are opt-in only — the default flips for new installs; no forced migration on upgrade.
- Two prerequisites the requirements assumed away: the library has NO `config/` dir (add an env-driven `config/config.exs` so `compile_env` resolves), and the main suite uses hand-written DDL (`ConcurrencyBootstrap`) that must be hand-qualified.
- TEST-02 can't be proven at runtime (`@schema_prefix` is compile-time) — the dual-prefix CI matrix must namespace the `_build` cache key by prefix + `mix compile --force`, or the `public` leg false-greens.
- Frozen-contract regression (`verify.public_api` + telemetry + compile-out, no new events) is a milestone done-criterion (Phase 56), not a feature.
- [Phase ?]: Application.compile_env/3 must be read at module attribute level (not inside def body); normalize via @prefix module attribute at compile time (Parapet.Spine.Schema v1.7 pattern)
- [Phase ?]: __prefix__/0 kept public (@doc false but callable) so Phase 54 doctor can read compiled prefix without future edit (D-01 discretion clause)
- [Phase ?]: Pure subtraction: six spine schemas switched from use Ecto.Schema to use Parapet.Spine.Schema; macro re-injects identical boilerplate plus @schema_prefix at compile time (PREFIX-01/02 done)
- [Phase ?]: Bootstrap reads Application.compile_env(:parapet, :schema_prefix) at module attribute level; q/1 qualifies ON/TABLE/REFERENCES targets only (not index names — Postgres invalid)

### Pending Todos

None.

### Blockers/Concerns

None. v1.7's dual-prefix CI matrix interacts with the v1.8 pipeline reshape (CI-01) — sequence accordingly when v1.8 starts.

## Deferred Items

Items acknowledged and deferred at v1.6 milestone close on 2026-06-29 (`override_closeout`):

| Category | Item | Status |
|----------|------|--------|
| uat_gap | phase-44 44-UAT.md (TOKEN-04 manual visual check) | testing — 1 pending scenario |
| verification_gap | phase-44 44-VERIFICATION.md (TOKEN-04 layout-shift, manual-only) | human_needed |
| verification_gap | phase-48 no 48-VERIFICATION.md (never ran /gsd-verify-work) | covered by milestone audit (Nyquist phase-48 compliant) |

All three trace to requirements that shipped and were human-verified in the live UI; the gap is in automated (ExUnit) coverage. v1.9 A11Y-01 is slated to ExUnit-pin them. See MILESTONES.md v1.6 → Known Gaps.

## Session Continuity

Last session: 2026-06-30T04:40:23.489Z
Stopped at: Completed 51-03-PLAN.md
Resume file: None
Next step: Plan Phase 51 with `/gsd-plan-phase 51` (Prefix Core & Test Seam)

## Operator Next Steps

- Plan the first v1.7 phase: `/gsd-plan-phase 51`
