---
phase: 33-documentation-polish
plan: "02"
subsystem: docs
tags: [maintaining, contributing, release-please, docker-compose, demo-app]
requires:
  - phase: 32-ci-supply-chain-hardening
    provides: release_gate branch-protection and supply-chain hardening context
provides:
  - maintainer release procedure checklist
  - Release Please-aware contributor commit taxonomy
  - documented demo app Docker Compose startup and smoke path
affects: [maintenance, contribution-flow, demo-app]
tech-stack:
  added: []
  patterns: [maintainer-only release checklist, modern docker compose with legacy fallback]
key-files:
  created:
    - MAINTAINING.md
  modified:
    - CONTRIBUTING.md
    - examples/demo_app/README.md
    - examples/demo_app/Makefile
key-decisions:
  - "Kept release policy authority in docs/release-policy.md and branch protection authority in docs/branch-protection.md."
  - "Preserved examples/demo_app/docker-compose.yml after docker compose config passed."
patterns-established:
  - "Root MAINTAINING.md is procedure-oriented and links to canonical policy/settings docs."
  - "Demo Makefile prefers docker compose while retaining docker-compose fallback."
requirements-completed: [MAT-05, MAT-06, MAT-08]
duration: 12min
completed: 2026-06-03
---

# Phase 33 Plan 02 Summary

**Maintainer release checklist, contributor commit taxonomy, and reproducible demo Compose smoke path**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-03T18:01:00Z
- **Completed:** 2026-06-03T18:12:53Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added root `MAINTAINING.md` with routine Release Please, staged `Release-As:`, `do-not-merge`, blocked-cut, and post-publish verification procedures.
- Expanded `CONTRIBUTING.md` with a Release Please-aware Conventional Commit taxonomy aligned to stable-line maintenance and feature work.
- Documented the demo app Compose startup, smoke-check, teardown, and port overrides, and updated the Makefile to prefer `docker compose` with `docker-compose` fallback.

## Task Commits

1. **Tasks 1-3: Maintainer docs, contributor taxonomy, and demo Compose guidance** - `ad5c39d` (docs)
2. **Review fix: Demo Compose custom-port smoke example** - `9333cae` (fix)

## Files Created/Modified

- `MAINTAINING.md` - Maintainer-only release procedure checklist.
- `CONTRIBUTING.md` - Release Please-aware Conventional Commit guidance.
- `examples/demo_app/README.md` - Docker Compose startup, smoke, teardown, and port override documentation.
- `examples/demo_app/Makefile` - Compose command wrapper preferring modern `docker compose`.

## Decisions Made

- Did not edit `examples/demo_app/docker-compose.yml` because `docker compose config` passed against the existing `db` + `web` service shape.
- Kept `MAINTAINING.md` checklist-oriented and linked to `docs/release-policy.md` and `docs/branch-protection.md` for canonical policy/settings truth.
- Updated the existing `CONTRIBUTING.md` instead of adding a second contribution document.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected custom-port smoke-check example**
- **Found during:** Advisory code review
- **Issue:** The custom-port example set `WEB_PORT=4001` only for `docker compose up`, then ran `curl` without the same variable, which would check port 4000 instead of the override.
- **Fix:** Added `WEB_PORT=4001` to the example `curl` command.
- **Files modified:** `examples/demo_app/README.md`
- **Verification:** `rg -q 'WEB_PORT=4001 curl -f http://localhost:\$\{WEB_PORT:-4000\}/parapet' examples/demo_app/README.md`
- **Committed in:** `9333cae`

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The fix keeps the documented demo smoke path accurate and does not change runtime behavior.

## Verification

- `test -f MAINTAINING.md && rg -q 'release_gate' MAINTAINING.md && rg -q 'Release-As:' MAINTAINING.md && rg -q 'do-not-merge' MAINTAINING.md && rg -q 'docs/release-policy.md' MAINTAINING.md && rg -q 'docs/branch-protection.md' MAINTAINING.md && rg -q 'Hex' MAINTAINING.md`
- `rg -q 'Release Please|ReleasePlease' CONTRIBUTING.md && rg -q 'feat:' CONTRIBUTING.md && rg -q 'fix:' CONTRIBUTING.md && rg -q 'docs:' CONTRIBUTING.md && rg -q 'refactor:' CONTRIBUTING.md && rg -q 'test:' CONTRIBUTING.md && rg -q 'chore:' CONTRIBUTING.md && rg -q 'BREAKING CHANGE' CONTRIBUTING.md && rg -q 'Stable-line maintenance|stable-line maintenance' CONTRIBUTING.md`
- `rg -q 'docker compose up --build' examples/demo_app/README.md && rg -q 'curl -f http://localhost:\$\{WEB_PORT:-4000\}/parapet' examples/demo_app/README.md && rg -q 'docker compose down -v' examples/demo_app/README.md && rg -q 'WEB_PORT' examples/demo_app/README.md && rg -q 'DB_PORT' examples/demo_app/README.md && rg -q 'demo only' examples/demo_app/README.md && rg -q '^up:' examples/demo_app/Makefile && rg -q 'docker compose' examples/demo_app/Makefile && rg -q 'docker-compose' examples/demo_app/Makefile && rg -q 'WEB_PORT' examples/demo_app/docker-compose.yml && rg -q 'DB_PORT' examples/demo_app/docker-compose.yml`
- `cd examples/demo_app && docker compose config >/dev/null` passed. Docker emitted a non-blocking warning that the Compose `version` attribute is obsolete.
- `rg -q 'WEB_PORT=4001 curl -f http://localhost:\$\{WEB_PORT:-4000\}/parapet' examples/demo_app/README.md`
- `MIX_ENV=dev mix docs --warnings-as-errors`
- `mix format --check-formatted mix.exs`

## Issues Encountered

Full `mix format --check-formatted` fails on pre-existing tracked Elixir files outside this docs phase's write set. I did not reformat unrelated runtime/test files in a documentation-polish phase. The Phase 33 touched Elixir file, `mix.exs`, passes scoped format verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 33 has delivered the remaining documentation and polish artifacts. Final phase verification should account for the pre-existing full-format failure separately from these docs changes.

---
*Phase: 33-documentation-polish*
*Completed: 2026-06-03*
