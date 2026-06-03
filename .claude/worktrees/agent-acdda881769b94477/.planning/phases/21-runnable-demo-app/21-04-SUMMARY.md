---
phase: 21-runnable-demo-app
plan: "04"
subsystem: infra
tags: [ci, github-actions, postgres, smoke-test, hex, getting-started]

# Dependency graph
requires:
  - phase: 21-runnable-demo-app
    plan: "03"
    provides: "examples/demo_app with smoke test, seeds, and Ecto migrations"
provides:
  - CI demo job with postgres:16-alpine service running smoke test behind test job
  - release_gate fan-in CI job requiring both test and demo to pass
  - getting-started.md Next steps link to Runnable Demo App
  - Confirmed examples/ absent from Hex package (DEMO-04)
affects: [22-release-readiness]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "demo CI job with explicit postgres service container (not runner pre-installed DB)"
    - "release_gate fan-in job as required status check target (needs: [test, demo])"
    - "cache keys scoped to examples/demo_app/mix.lock (not **/mix.lock) to avoid root cache collision"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - docs/getting-started.md

key-decisions:
  - "Use explicit postgres:16-alpine service container in demo job (not runner's pre-installed postgres) for isolation"
  - "release_gate job has echo step to satisfy GitHub Actions Pitfall 5 (job must have runs-on + at least one step)"
  - "Branch protection must be human-configured after workflow has run on a PR (gh api PUT rejected — branch not yet protected)"

patterns-established:
  - "Fan-in gate pattern: release_gate needs: [test, demo], no continue-on-error anywhere"
  - "Demo CI cache scoped per-app: examples/demo_app/{deps,_build} with specific mix.lock key"

requirements-completed: [DEMO-03, DEMO-04]

# Metrics
duration: ~2min
completed: 2026-05-25
---

# Phase 21 Plan 04: CI Gate + Docs Summary

**demo + release_gate CI jobs added (postgres service, smoke test, fan-in gate); examples/ confirmed absent from Hex package; getting-started.md links the demo app; checkpoint approved by human**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-25T16:12:22Z
- **Completed:** 2026-05-25T16:15:00Z
- **Tasks:** 2 of 2 complete
- **Files modified:** 2

## Accomplishments

- Added `demo:` job to `.github/workflows/ci.yml` with postgres:16-alpine service container, `needs: [test]`, MIX_ENV test, proper cache keys scoped to `examples/demo_app/mix.lock`, and sequential steps: deps.get, ecto.create+migrate, seeds, smoke test
- Added `release_gate:` job (`needs: [test, demo]`, runs-on ubuntu-latest, echo step) as CI fan-in gate — zero `continue-on-error` anywhere (D-07 / DEMO-03)
- YAML validated: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` exits 0
- Appended `[Runnable Demo App]` bullet to `docs/getting-started.md` Next steps (D-11 exact text)
- `mix hex.build` confirmed: no path under `examples/` appears in the Files list (DEMO-04 / D-10)
- Task 2 checkpoint cleared: human approved ("approved") confirming verification complete

## Task Commits

1. **Task 1: Add demo + release_gate CI jobs and getting-started link** - `d3dbaeb` (feat)
2. **Task 2: Checkpoint approval recorded** - human verified (2026-05-25)

## Files Created/Modified

- `.github/workflows/ci.yml` - Added demo job (postgres service, smoke test, cache) and release_gate fan-in job
- `docs/getting-started.md` - Appended Runnable Demo App bullet to Next steps

## Decisions Made

- Use explicit `services: postgres:` block in demo job (runner's pre-installed postgres is not reliable for isolated CI jobs per the research notes).
- Cache keys use `examples/demo_app/mix.lock` (not `**/mix.lock`) to avoid colliding with the root `deps` cache.
- `release_gate` job has a `run: echo "All required CI checks passed"` step to satisfy GitHub Actions' requirement that every job have `runs-on` + at least one step (Pitfall 5 from PATTERNS.md).
- No `continue-on-error` added anywhere (strict requirement D-07).

## Hex Dry-Run Result (DEMO-04)

`mix hex.build` output confirmed the Files list contains no path beginning with `examples/`. The `files:` whitelist in `mix.exs` (line 42) omits `examples/` by omission — no change to mix.exs was required or made. The full output was scanned with `grep 'examples/'` which returned empty — confirmed excluded.

## Checkpoint Approval (Task 2)

Human responded "approved" to the `checkpoint:human-verify` gate on 2026-05-25.

**Approved items:**
1. **REQUIRED STATUS CHECK (DEMO-03):** `release_gate` is to be configured as a required status check on `main` after the workflow runs on the first PR. The `gh api PUT` returned 404 at checkpoint time (branch protection not yet set up — expected behavior per plan). One-time manual step: add `release_gate` to required status checks via GitHub Settings → Branches or via `gh api -X PUT repos/szTheory/parapet/branches/main/protection/required_status_checks -f 'checks[][context]=release_gate'`.
2. **HEX EXCLUSION (DEMO-04):** Confirmed no `examples/` path in published package.
3. **LIVE DEMO (DEMO-01 / DEMO-02):** Seeded Operator UI confirmed at /parapet.

## Deviations from Plan

None — plan executed exactly as written. The `gh api` branch-protection attempt was made as specified (branch not yet protected → expected fallback to human checkpoint per plan).

## Issues Encountered

- `mix hex.build --dry-run` is not a supported flag in this version of Hex (error: `--dry-run: Unknown option`). Used `mix hex.build` (without flag) and scanned output for `examples/` paths. Result is equivalent — no `examples/` path found.

## One-Time Manual Step Remaining

**Branch protection (DEMO-03):** After the first PR triggers the CI workflow, add `release_gate` as a required status check on `main`:
- GitHub UI: Settings → Branches → branch protection rule for `main` → "Require status checks to pass before merging" → add `release_gate`
- Or via CLI once the check name is selectable: `gh api -X PUT repos/szTheory/parapet/branches/main/protection/required_status_checks -f 'checks[][context]=release_gate'`

## Next Phase Readiness

- CI gate is fully wired and checkpoint cleared
- All automated work committed and verified (d3dbaeb)
- Branch protection is a one-time post-PR manual step (documented above)
- DEMO-03 and DEMO-04 requirements satisfied

## Self-Check: PASSED

- Task 1 commit d3dbaeb verified present in git history
- `.github/workflows/ci.yml` changes present in worktree branch (worktree-agent-a316a30b0ed91830c)
- `docs/getting-started.md` demo link present in worktree branch
- SUMMARY.md written to `.planning/phases/21-runnable-demo-app/21-04-SUMMARY.md`

---
*Phase: 21-runnable-demo-app*
*Completed: 2026-05-25*
