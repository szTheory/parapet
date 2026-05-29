---
phase: 29-stability-adopter-onboarding
plan: 01
subsystem: api
tags: [stability, docs, recovery, verify-public-api, tdd]

# Dependency graph
requires:
  - phase: 24-recovery-behaviour-capability-allowlist
    provides: "Parapet.Recovery behaviour with 4 @callbacks and Experimental admonition"
  - phase: 25-wire-confirm-claimservice-preview-confirm-ux
    provides: "confirm_runbook_step/4 with {:short_circuited, reason} and {:conflicted, claim_id} variants"
provides:
  - "Parapet.Recovery graduated to Stable tier (moduledoc flip + docs/stability.md row move)"
  - "Deprecation/Compatibility Register additive-variant note for confirm_runbook_step/4"
  - "Wave-0 regression guard in verify.public_api_test.exs asserting Stable classification"
affects:
  - 29-02-gen-recovery-mix-task
  - 29-03-doctor-recovery-check
  - 29-04-recovery-actions-guide

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stable-tier moduledoc flip: replace Experimental {: .warning} with Stable {: .info} to trigger verify.public_api regex auto-reclassification"
    - "Additive-variant compat note in Deprecation Register for no-removal-in-1.x promise"
    - "TDD regression guard: Code.fetch_docs/1 + detect_tier_from_text/1 to catch future admonition regression"

key-files:
  created: []
  modified:
    - lib/parapet/recovery.ex
    - docs/stability.md
    - test/mix/tasks/verify.public_api_test.exs

key-decisions:
  - "Placed Recovery row after Parapet.Operator in Stable table (logical grouping, operator-adjacent surface)"
  - "Used Code.fetch_docs/1 in regression test rather than hardcoded string — test targets live compiled module so admonition revert is caught at compile time"
  - "Compatibility Register row uses 'Compatibility note — Additive' Kind framing (not 'deprecated') since nothing is being deprecated"

patterns-established:
  - "Module stability graduation: flip moduledoc admonition + move docs/stability.md row atomically (Pitfall 2 avoided)"
  - "Regression guard pattern: fetch live BEAM docs via Code.fetch_docs/1 → detect_tier_from_text/1 assertion"

requirements-completed: [STAB-07]

# Metrics
duration: 15min
completed: 2026-05-29
---

# Phase 29 Plan 01: Stability — Graduate Parapet.Recovery to Stable Summary

**Parapet.Recovery graduated from Experimental to Stable via two-anchor flip: moduledoc admonition to `Stable {: .info}`, docs/stability.md row moved to Stable table, additive confirm_runbook_step/4 variants named in Deprecation Register, and Wave-0 regression guard added to verify.public_api tests**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-29T00:55:00Z
- **Completed:** 2026-05-29T01:01:10Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Flipped `lib/parapet/recovery.ex` moduledoc from `Experimental {: .warning}` to `Stable {: .info}` with callback-freeze prose — enables `mix verify.public_api` regex auto-reclassification without editing the task code (D-04)
- Moved `Parapet.Recovery` row from Experimental to Stable table in `docs/stability.md`; added compat note to Deprecation Register for additive `{:short_circuited, reason}` / `{:conflicted, claim_id}` variants of `confirm_runbook_step/4` (D-06)
- Added 2-case Wave-0 regression guard in `verify.public_api_test.exs`: live `Code.fetch_docs/1` fetch asserts `:stable`; companion test proves old Experimental string returns `:experimental` (regression is real, not a tautology)

## Task Commits

1. **Task 1: Flip recovery.ex moduledoc to Stable + add callback-freeze prose** — `10ff69f` (feat)
2. **Task 2: Move Recovery row to Stable table + add Deprecation Register compat note** — `4ff05f8` (docs)
3. **Task 3: Add Wave-0 regression guard — Recovery classifies as Stable (STAB-07)** — `a563405` (test)

## Files Created/Modified

- `lib/parapet/recovery.ex` — Replaced Experimental admonition with verbatim `Stable {: .info}` string; added callback-freeze prose naming id/0, label/0, preview/2, execute/2 as frozen 1.x contract
- `docs/stability.md` — Recovery row moved to Stable table (after Parapet.Operator); Experimental row removed; Deprecation Register extended with additive-variant compat note for confirm_runbook_step/4
- `test/mix/tasks/verify.public_api_test.exs` — New `describe "Parapet.Recovery stable reclassification"` block with 2 cases

## Decisions Made

- Placed Recovery row after `Parapet.Operator` in Stable table — logically adjacent to operator-facing surfaces
- Regression test uses `Code.fetch_docs(Parapet.Recovery)` (live BEAM) rather than a hardcoded string constant — test fails if admonition is reverted in source and recompiled
- Compat Register row uses "Compatibility note — Additive" Kind framing because nothing is being deprecated; the additive variants land in 1.x and are promised to stay

## Deviations from Plan

None — plan executed exactly as written.

The plan referenced `test/mix/tasks/verify_public_api_test.exs` (underscore) but the actual file is `test/mix/tasks/verify.public_api_test.exs` (dot, matching the mix task name). This was a naming discrepancy in the plan; the correct file was used.

## Issues Encountered

**Worktree base alignment:** The worktree branch was created from `a824e1f` (pre-Phase-24), requiring a `git reset --hard` to the current main HEAD (`5ac56b1`) before Phase-24+ files (recovery.ex, etc.) were available. This is a one-time worktree initialization issue, not a plan defect.

**Verification context:** `mix compile` and `mix verify.public_api` run from the main project directory see the main repo's source (not the worktree's changes). Worktree verification used `MIX_BUILD_PATH=/tmp/parapet_worktree_build MIX_DEPS_PATH=/Users/jon/projects/parapet/deps mix test` from the worktree root. Both the test suite and `mix verify.public_api` confirm `Parapet.Recovery → tier: stable` after the moduledoc flip.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. This plan is doc-only + test-only modifications. T-29-02 (frozen callback surface) mitigated: acceptance criteria assert `@callback` count == 4 and `__using__/1` untouched.

## Known Stubs

None — no stub patterns introduced. All data flows to real verified outputs.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `Parapet.Recovery` is now Stable-tier — `mix verify.public_api` auto-reclassifies via the moduledoc admonition (D-04)
- The three-way invariant (moduledoc ↔ docs/stability.md ↔ verify.public_api) is consistent (Pitfall 2 avoided)
- Wave-0 regression guard active — future accidental revert to Experimental is caught by the test suite
- Plans 29-02, 29-03, 29-04 can proceed; they depend on Stable graduation being in place

## Self-Check: PASSED

- FOUND: 29-01-SUMMARY.md (this file)
- FOUND: lib/parapet/recovery.ex
- FOUND: docs/stability.md
- FOUND: test/mix/tasks/verify.public_api_test.exs
- FOUND commit 10ff69f (Task 1)
- FOUND commit 4ff05f8 (Task 2)
- FOUND commit a563405 (Task 3)

---
*Phase: 29-stability-adopter-onboarding*
*Completed: 2026-05-29*
