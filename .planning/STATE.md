---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Postgres Schema Isolation & Upgrade Path
current_phase: 7
status: Awaiting next milestone
stopped_at: Completed 56-04-PLAN.md (verification/UAT records; phase complete)
last_updated: "2026-07-02T17:12:40.403Z"
last_activity: 2026-07-02
last_activity_desc: Milestone v1.7 completed and archived
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 21
  completed_plans: 21
  percent: 100
current_phase_name: contract-release-hardening
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-02 after v1.7 milestone)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** v1.7 shipped — planning next milestone (v1.8 CI/CD performance & DX). Run `/gsd-new-milestone`.

## Current Position

Phase: Milestone v1.7 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-07-02 — Milestone v1.7 completed and archived

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
| 52 | 4 | - | - |
| 53 | 4 | - | - |
| 54 | 4 | - | - |
| 55 | 2 | - | - |
| 56 | 4 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
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
- [Phase ?]: D-11: pruned matrix.include for CI schema_prefix axis (+1 cell 3→4); D-13: only _build namespaced; D-14: leg guard reuses Schema.normalize/1
- [Phase ?]: check_schema/0 made @doc false public (not private defp) to enable direct unit-test invocation — mirrors __prefix__/0 pattern (DOCTOR-01 testability)
- [Phase ?]: Drift cond branch ordered first in check_schema/0 so DB-less mix parapet.doctor --ci always catches stale-compile drift without a live repo (D-01/D-05)
- [Phase ?]: Parapet.Spine.SchemaMoveNotice shared helper: emit_for_spine/3 preserves gen.spine DBA notice wording byte-for-byte; emit_for_move/3 adds move-context trailing instruction (D-12b single-source)
- [Phase ?]: resolve_prefix/2 always defaults to {:ok, parapet} when both flag and config normalize to nil; nil-leg in gen.schema.move is reachable only when resolver explicitly returns nil (not via --schema public CLI)
- [Phase ?]: Track A nil-leg guard: if is_nil(@prefix) do / describe block at module level (D-19)
- [Phase ?]: UPG-05 fitness fn: explicit file list excludes move task itself; dual forbidden patterns catch both invocation and alias forms (D-20)
- [Phase ?]: Six tables required in fixture for round-trip test
- [Phase ?]: Postgrex.Error is correct type for abort leg assertions
- [Phase ?]: Sentinel migration version 0 sorts before all spine migrations; down/0 non-cascading prevents silent schema deletion
- [Phase ?]: SAFE-03 smoke assertions use schema_prefix() not literal parapet for leg-agnostic correctness
- [Phase ?]: Demo CI compile step in existing demo job (not new job) keeps release_gate needs list unchanged
- [Phase ?]: Single-source rule (D-05): upgrade-1.x.md is sole home for Track A/B mechanics
- [Phase ?]: HexDocs double-registration: upgrade-1.x.md added to both mix.exs extras: AND groups_for_extras Guides: (D-08 / Landmine 3)
- [Phase ?]: migration-v1.md Step 3 is a first-class step (not checklist bullet) so do-nothing upgrader sees schema choice before first spine query fails (D-09 C2-refined)
- [Phase ?]: test summary
- [Phase ?]: Bare-source test ordering: attach Ecto telemetry handler AFTER Sandbox.checkout + reset!() to avoid nil-source TRUNCATE events; use schema-module form for all/1 to ensure put_source/2 populates :source
- [Phase ?]: Use atom form :'Elixir.Ecto.Adapters.SQL.Sandbox' to bypass alias Parapet.Metrics.Ecto shadowing the Ecto name when calling sandbox functions in test modules
- [Phase ?]: [Phase 56-02]: SAFE-01 proven — mix verify.public_api exits 0; compile-time @schema_prefix attribute is structurally impossible to appear in public API surface; schema_prefix/0 is pre-existing Stable export
- [Phase ?]: D-02 LOCKED two-part CHANGELOG feat(schema) banner: headline reassurance (no data migrated automatically) + distinct existing-adopter action-required line (config :parapet, schema_prefix: nil + link to docs/upgrade-1.x.md)
- [Phase ?]: D-10 confirmed: SAFE-01/02/04 enforcement is existing CI (lint Verify Public API + test ExUnit suite); no new bespoke gate or mix ci alias added

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

Last session: 2026-07-02T16:30:39.990Z
Stopped at: Completed 56-04-PLAN.md (verification/UAT records; phase complete)
Resume file: None
Next step: Discuss Phase 56 with `/gsd-discuss-phase 56` (Contract & Release Hardening) — no CONTEXT.md yet

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
