---
phase: 32-ci-supply-chain-hardening
plan: 01
subsystem: infra
tags: [github-actions, ci, elixir, otp, supply-chain]
requires: []
provides:
  - Multi-version Elixir/OTP CI matrix
  - SHA-pinned CI and release workflow actions
  - Matrix-aware Mix and build caches
affects: [ci, release, supply-chain]
tech-stack:
  added: []
  patterns:
    - GitHub Actions jobs use a stable release_gate aggregate over matrix jobs
    - GitHub Actions references are pinned to immutable commit SHAs
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/release-please.yml
key-decisions:
  - "Kept release_gate unchanged as the stable required branch-protection status check."
patterns-established:
  - "Matrix cache keys include both matrix.elixir and matrix.otp to avoid cross-version cache collisions."
  - "Third-party GitHub Actions use exact 40-character commit SHAs rather than mutable tags."
requirements-completed: [MAT-01, MAT-02]
duration: 0 min
completed: 2026-06-03
---

# Phase 32 Plan 01: CI Supply Chain Hardening Summary

**Elixir/OTP CI matrix with SHA-pinned GitHub Actions and version-isolated caches**

## Performance

- **Duration:** 0 min
- **Started:** 2026-06-03T17:18:00Z
- **Completed:** 2026-06-03T17:23:44Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added Elixir 1.19.0 across OTP 26.x, 27.x, and 28.x to the `lint`, `test`, and `demo` CI jobs.
- Updated Mix and `_build` cache keys to include `${{ matrix.elixir }}` and `${{ matrix.otp }}`.
- Replaced floating GitHub Action tags in CI and release workflows with exact commit SHAs.

## Task Commits

Each task was committed atomically:

1. **Task 1: CI Pipeline Matrix and SHA Pinning** - `12a66f1` (chore)
2. **Task 2: Release Pipeline SHA Pinning** - `97a640d` (chore)

**Plan metadata:** committed separately after summary creation.

## Files Created/Modified

- `.github/workflows/ci.yml` - Adds matrix execution, matrix-aware caches, and pinned action SHAs.
- `.github/workflows/release-please.yml` - Pins checkout, setup-beam, and release-please-action references to exact SHAs.

## Decisions Made

- Kept `release_gate` unchanged so branch protection can continue to depend on one stable aggregate status check while upstream jobs expand into a matrix.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `grep -q 'matrix.otp' .github/workflows/ci.yml`
- `grep -q '34e114876b0b11c390a56381ad16ebd13914f8d5' .github/workflows/ci.yml`
- `grep -q '5c625bfb5d1ff62eadeeb3772007f7f66fdcf071' .github/workflows/release-please.yml`
- `yq e '.' .github/workflows/ci.yml`
- `yq e '.' .github/workflows/release-please.yml`
- `rg 'uses: [^@]+@(v[0-9]+|main|master)$' .github/workflows/ci.yml .github/workflows/release-please.yml` returned no matches.

## Self-Check: PASSED

All task acceptance criteria and plan-level verification checks passed.

## Next Phase Readiness

CI and release workflow hardening is complete. The phase is ready for Dependabot and branch-protection close-out.

---
*Phase: 32-ci-supply-chain-hardening*
*Completed: 2026-06-03*
