---
phase: 21-runnable-demo-app
plan: 06
subsystem: infra
tags: [github, ci, branch-protection, release-gate]
requires:
  - phase: 21-04
    provides: release_gate CI job wired to test and demo jobs
provides:
  - main branch protection requiring the release_gate status check
affects: [demo-app, ci, release-process]
tech-stack:
  added: []
  patterns: [github-branch-protection-as-ci-enforcement]
key-files:
  created: [.planning/phases/21-runnable-demo-app/21-06-SUMMARY.md]
  modified: []
key-decisions:
  - "Configured branch protection through the GitHub API using the full protection payload so release_gate is enforced without rewriting workflow code."
patterns-established:
  - "Repository-level merge protection for demo smoke coverage lives in GitHub branch protection, not only in .github/workflows/ci.yml."
requirements-completed: [DEMO-03]
duration: 8 min
completed: 2026-05-25
---

# Phase 21 Plan 06: Configure Release Gate Summary

**GitHub branch protection now requires the `release_gate` status check on `main`, turning the demo smoke test into a real merge blocker.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-25T21:48:00Z
- **Completed:** 2026-05-25T21:56:00Z
- **Tasks:** 1
- **Files modified:** 0

## Accomplishments
- Confirmed the repo previously returned `404 Branch not protected` for `main`.
- Applied the documented branch-protection payload through `gh api`.
- Verified `gh api repos/szTheory/parapet/branches/main/protection/required_status_checks --jq '.checks'` now returns `release_gate`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Configure release_gate as a required status check on main** - external GitHub settings change via `gh api`

**Plan metadata:** not yet committed

## Files Created/Modified
- `.planning/phases/21-runnable-demo-app/21-06-SUMMARY.md` - Records the branch-protection change and verification evidence.

## Decisions Made
- Used the full branch-protection `PUT` payload from the plan instead of a narrower status-checks-only update to avoid ambiguous partial settings changes.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

`gh auth status` timed out talking to the keyring, but authenticated API calls still succeeded and the protection change applied cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`release_gate` is enforced on `main`, so DEMO-03's repository-settings gap is closed.
Phase 21 still depends on Plan 05 finishing its demo-app code verification before the phase can be marked complete.

---
*Phase: 21-runnable-demo-app*
*Completed: 2026-05-25*
