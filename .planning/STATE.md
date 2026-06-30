---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Postgres Schema Isolation & Upgrade Path
current_phase: 52
current_phase_name: propagation-proof-guards-ci-dual-prefix-matrix
status: executing
stopped_at: "Completed 52-01-PLAN.md: sealed WR-01..04 (normalize/1, safe_ident!/1, Evidence delegation, test rewrite)"
last_updated: "2026-06-30T15:28:31.231Z"
last_activity: 2026-06-30
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 7
  completed_plans: 5
  percent: 17
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-30 after Phase 51)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Phase 52 — propagation-proof-guards-ci-dual-prefix-matrix

## Current Position

Phase: 52 (propagation-proof-guards-ci-dual-prefix-matrix) — EXECUTING
Plan: 3 of 4
Status: Ready to execute
Last activity: 2026-06-30

Progress: [██████░░░░] 57%

## Milestone Roadmap (v1.7)

Continuing phase numbering from v1.6 (ended at Phase 50). Hard dependency chain: the config seam + bootstrap qualification (Phase 51) must land before propagation/guards can run under the prefix; the dual-prefix CI matrix (Phase 52) is the honest proof; generators → upgrade path+doctor → demo+docs → release hardening follow.

- [x] **51 Prefix Core & Test Seam** — PREFIX-01..04, TEST-01, TEST-02 ✓ 2026-06-30
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
| Phase 52 P01 | 12 | 3 tasks | 7 files |
| Phase 52 P02 | 2 | 1 tasks | 1 files |

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
- [Phase 51]: Application.compile_env/3 must be read at module attribute level (not inside def body); normalize via @prefix module attribute at compile time (Parapet.Spine.Schema v1.7 pattern)
- [Phase 51]: __prefix__/0 kept public (@doc false but callable) so Phase 54 doctor can read compiled prefix without future edit (D-01 discretion clause)
- [Phase 51]: Pure subtraction: six spine schemas switched from use Ecto.Schema to use Parapet.Spine.Schema; macro re-injects identical boilerplate plus @schema_prefix at compile time (PREFIX-01/02 done)
- [Phase 51]: Bootstrap reads Application.compile_env(:parapet, :schema_prefix) at module attribute level; q/1 qualifies ON/TABLE/REFERENCES targets only (not index names — Postgres invalid)
- [Phase ?]: Parapet.Spine.Schema.Normalizer private submodule: Elixir cannot call same-module functions from compile-time module attributes — submodule-first approach is the idiomatic solution
- [Phase ?]: Evidence.schema_prefix/0 delegation to Schema.__prefix__(): frozen compile-time value eliminates runtime/compile split-brain by construction (WR-03)
- [Phase ?]: safe_ident!/1 allowlist (^[a-z_][a-z0-9_]*$ + 63-byte limit) folded into normalize/1: every prefix resolution path guarded before DDL interpolation (WR-04, T-52-01 threat)
- [Phase ?]: PROP-02 backtick lookbehind: excluded doc-string prefix: mentions added by Plan 01 from the guard fingerprint

### Pending Todos

None.

### Blockers/Concerns

v1.7's dual-prefix CI matrix interacts with the v1.8 pipeline reshape (CI-01) — sequence accordingly when v1.8 starts.

Phase 51 code review (advisory, `51-REVIEW.md`) surfaced 4 warnings that map onto Phase 52's guard/CI-matrix scope — fold into Phase 52 planning:

- ⚠️ [Phase 52] WR-01: the D-05 "agreement test" compares two test-local mirror copies, not the production normalizers (`config.exs` / `Schema.__prefix__/0`) — it cannot detect the drift it claims to guard. The dual-prefix CI matrix (TEST-03) is the real cross-leg proof.
- ⚠️ [Phase 52] WR-02: `nil` normalizes asymmetrically across the three real copies (unset env → `"parapet"`; resolver/runtime `nil → nil`) — the matrix should pin both legs explicitly.
- ⚠️ [Phase 52] WR-03: runtime `Evidence.schema_prefix/0` reads mutable app-env while schemas freeze at compile time — runtime/compile split-brain; the runtime-`prefix:` ban guard (PROP) + Phase-54 doctor are the intended mitigations.
- ⚠️ [Phase 52→53] WR-04: prefix interpolated into raw DDL identifiers without quoting (`concurrency_bootstrap.ex`) — the template a production generator (Phase 53 GEN) will copy; quote/validate before it propagates.

## Deferred Items

Items acknowledged and deferred at v1.6 milestone close on 2026-06-29 (`override_closeout`):

| Category | Item | Status |
|----------|------|--------|
| uat_gap | phase-44 44-UAT.md (TOKEN-04 manual visual check) | testing — 1 pending scenario |
| verification_gap | phase-44 44-VERIFICATION.md (TOKEN-04 layout-shift, manual-only) | human_needed |
| verification_gap | phase-48 no 48-VERIFICATION.md (never ran /gsd-verify-work) | covered by milestone audit (Nyquist phase-48 compliant) |

All three trace to requirements that shipped and were human-verified in the live UI; the gap is in automated (ExUnit) coverage. v1.9 A11Y-01 is slated to ExUnit-pin them. See MILESTONES.md v1.6 → Known Gaps.

## Session Continuity

Last session: 2026-06-30T15:27:57.973Z
Stopped at: Completed 52-01-PLAN.md: sealed WR-01..04 (normalize/1, safe_ident!/1, Evidence delegation, test rewrite)
Resume file: None
Next step: Discuss Phase 52 with `/gsd-discuss-phase 52` (Propagation Proof, Guards & CI Dual-Prefix Matrix) — no CONTEXT.md yet

## Operator Next Steps

- Discuss the next v1.7 phase: `/gsd-discuss-phase 52` (then `/gsd-plan-phase 52`)
