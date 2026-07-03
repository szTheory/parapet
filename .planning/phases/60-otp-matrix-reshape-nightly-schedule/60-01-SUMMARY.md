---
phase: 60-otp-matrix-reshape-nightly-schedule
plan: "01"
subsystem: infra
tags: [github-actions, ci, otp, elixir, matrix, cron]

requires:
  - phase: 59-ci-reliability-false-green-guard
    provides: dual-prefix _build cache key + mix compile --force invariant (D-02c carried forward)

provides:
  - matrix-config resolver job emitting single-line JSON (PR=1 cell, push/schedule=4 cells)
  - nightly schedule trigger cron '17 3 * * *'
  - event-scoped concurrency group (github.event_name in group key)
  - OTP 26 / Elixir 1.19 retirement from CI (new toolchain: Elixir 1.20.2 x OTP {27,28,29})
  - demo job converted to plain single-OTP-28 job, skipped on PRs
  - release_gate hardened with D-03c truth table (case success|skipped for demo, strict for lint+test)
  - D-11 tech-debt retirement comment in ci.yml (asymmetry-explainer, D-04d)

affects: [phase-60-plan-02, CI runs on all future PRs and pushes, nightly cron runs]

tech-stack:
  added: []
  patterns:
    - "matrix-config resolver job: bare run: step emits single-line JSON to GITHUB_OUTPUT, test job consumes via fromJson()"
    - "Event-conditional CI: PR gets 1 trimmed cell, push/schedule gets full 4-cell matrix"
    - "release_gate truth table: strict success for lint/test, case success|skipped for demo (blocks cancelled)"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "Single-line JSON to GITHUB_OUTPUT (multi-line heredoc corrupts output — D-02a)"
  - "Every include object carries all 3 keys (elixir, otp, schema_prefix) to prevent blank-interp false-green (D-02d)"
  - "OTP 26 dropped (EOL May 2026); Elixir bumped to 1.20.2 (required for OTP 27+ CI pin — D-01a/b)"
  - "demo converted to plain job with if: github.event_name != 'pull_request' (D-03b)"
  - "release_gate case success|skipped for demo (not != failure) to block cancelled runs (D-03c)"
  - "cron '17 3 * * *' (house :17 convention, not illustrative '0 3' from roadmap — D-03a)"
  - "No version-type: strict added to setup-beam (strict errors against .x OTP ranges — D-01d)"

patterns-established:
  - "matrix-config resolver pattern: use for any future event-conditional matrix needs in this repo"
  - "release_gate case pattern: use case success|skipped for jobs with legitimate PR-skip paths"

requirements-completed: [MATRIX-01, MATRIX-02, MATRIX-03, MATRIX-04]

coverage:
  - id: D1
    description: "matrix-config resolver job emits 1-cell JSON on pull_request, 4-cell JSON on push/schedule"
    requirement: MATRIX-01
    verification:
      - kind: other
        ref: "grep 'test-matrix={\"include\"' .github/workflows/ci.yml — PR branch: 1 object, else: 4 objects"
        status: pass
    human_judgment: false
  - id: D2
    description: "Nightly schedule trigger cron '17 3 * * *' added to workflow"
    requirement: MATRIX-04
    verification:
      - kind: other
        ref: "grep -c \"cron: '17 3 \\* \\* \\*'\" .github/workflows/ci.yml == 1"
        status: pass
    human_judgment: false
  - id: D3
    description: "OTP 26 / Elixir 1.19 retired; toolchain is Elixir 1.20.2 x OTP {27,28,29}"
    requirement: MATRIX-02
    verification:
      - kind: other
        ref: "grep -c '1\\.19\\.0' .github/workflows/ci.yml == 0; grep -c \"'26\\.x'\" == 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "demo job is plain OTP-28 job skipped on pull_request; no strategy/matrix block"
    requirement: MATRIX-03
    verification:
      - kind: other
        ref: "grep 'if: github.event_name != .pull_request' .github/workflows/ci.yml; no strategy: in demo job"
        status: pass
    human_judgment: false
  - id: D5
    description: "release_gate hardened: strict success for lint/test, case success|skipped for demo, matrix-config in needs"
    requirement: MATRIX-04
    verification:
      - kind: other
        ref: "grep 'success|skipped' .github/workflows/ci.yml; grep 'needs:.*matrix-config' release_gate"
        status: pass
    human_judgment: false
  - id: D6
    description: "actionlint reports no errors on the reshaped ci.yml"
    requirement: MATRIX-01
    verification:
      - kind: other
        ref: "actionlint .github/workflows/ci.yml (run locally — exit 0)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-03
status: complete
---

# Phase 60 Plan 01: OTP Matrix Reshape & Nightly Schedule Summary

**matrix-config resolver job (PR=1 cell, push/nightly=4 cells) with Elixir 1.20.2 x OTP {27,28,29}, plain OTP-28 demo, hardened release_gate truth table, and nightly cron '17 3 * * *'**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-07-03T00:42:00Z
- **Completed:** 2026-07-03T00:52:22Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added `matrix-config` resolver job emitting single-line JSON to `$GITHUB_OUTPUT` — PR gets 1 trimmed cell (OTP 28/Elixir 1.20.2/parapet), push/schedule gets 4 full cells (OTP 27+28+29 x parapet, OTP 28 x public)
- Retired OTP 26 (EOL May 2026) and Elixir 1.19.0; bumped all lint-once cache keys and setup-beam pin to Elixir 1.20.2; zero legacy tokens survive
- Added nightly `schedule: cron: '17 3 * * *'` trigger and event-scoped concurrency group (includes `github.event_name`)
- Converted demo to a plain OTP-28 job with `if: github.event_name != 'pull_request'`, literal versions in all cache keys
- Hardened `release_gate` with D-03c truth table: strict success for lint-once and test; `case success|skipped` for demo (blocks cancelled, passes PR-skipped); `matrix-config` added to `needs`
- Preserved D-02c invariant: `_build` cache key retains `${{ matrix.schema_prefix }}` and `mix compile --force` step untouched
- Added D-04d asymmetry-explainer comment and D-05a OTP-29 compat note on `matrix-config` job
- `actionlint` passes clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Add schedule trigger, event-scoped concurrency, and matrix-config resolver job** - `ce474c6` (feat)
2. **Task 2: Wire test to resolver, retire OTP 26/Elixir 1.19, convert demo to plain job** - `4fc05ee` (feat)
3. **Task 3: Harden release_gate against the false-green truth table** - `fcd8881` (feat)

## Files Created/Modified

- `.github/workflows/ci.yml` - Complete CI reshape: matrix-config resolver, schedule trigger, event-scoped concurrency, lint-once toolchain bump to 1.20.2, test wired to resolver, demo converted to plain OTP-28 job, release_gate hardened with truth table

## Decisions Made

- **Single-line JSON to GITHUB_OUTPUT** (D-02a): multi-line heredoc body corrupts the output; emitted the full JSON on one `echo` line per footgun documentation
- **All 3 keys in every include object** (D-02d): `elixir`, `otp`, `schema_prefix` all present so `${{ matrix.* }}` never resolves to empty string (blank-interp false-green)
- **cron '17 3 * * *'** (D-03a): intentionally not the illustrative `'0 3 * * *'` from ROADMAP — house `:17` convention, matches `verify-published-release.yml`
- **No version-type: strict** (D-01d): strict mode errors against `.x` OTP range strings; default loose + exact `1.20.2` resolves reproducibly
- **case success|skipped pattern** (D-03c): `!=  failure` would silently pass a cancelled demo run; the case pattern blocks all non-pass/non-skipped results correctly
- **matrix-config added to release_gate.needs** (D-03c): resolver failure now produces a clear gate failure message rather than silently succeeding with no cells

## Deviations from Plan

None - plan executed exactly as written. All decisions matched locked D-codes from 60-CONTEXT.md. The `cron: '17 3 * * *'` vs roadmap's illustrative `'0 3 * * *'` is explicitly documented as intentional in D-03a (not a deviation).

## Issues Encountered

None. All footguns pre-documented in the plan and CONTEXT.md were avoided on first implementation.

## Self-Check

## Self-Check: PASSED

Verified:
- `.github/workflows/ci.yml` exists and is valid YAML (`python3 yaml.safe_load` exits 0)
- `actionlint .github/workflows/ci.yml` exits 0 (no errors)
- Commit `ce474c6` exists (Task 1: schedule + concurrency + matrix-config)
- Commit `4fc05ee` exists (Task 2: test wiring + toolchain retire + demo conversion)
- Commit `fcd8881` exists (Task 3: release_gate hardening)
- All plan verification assertions pass (see Verification section below)

## Verification Results

All overall phase-1 checks pass:

| Check | Result |
|-------|--------|
| `python3 yaml.safe_load(ci.yml)` | PASS (exit 0) |
| `grep -c "cron: '17 3 \\* \\* \\*'" ci.yml == 1` | PASS (count: 1) |
| `grep -c '1\\.19\\.0' ci.yml == 0` | PASS (count: 0) |
| `grep -c "'26\\.x'" ci.yml == 0` | PASS (count: 0) |
| `grep -c 'matrix.schema_prefix' ci.yml >= 1` | PASS (count: 3) |
| `grep -c 'mix compile --force' ci.yml >= 1` | PASS (count: 1) |
| `grep -c 'fromJson(needs.matrix-config.outputs.test-matrix)' ci.yml == 1` | PASS (count: 1) |
| `grep -c "if: github.event_name != 'pull_request'" ci.yml >= 1` | PASS (count: 1) |
| `grep -c 'if: always()' ci.yml >= 1` | PASS (count: 1) |
| `actionlint .github/workflows/ci.yml` | PASS (no errors) |

## Next Phase Readiness

- Plan 60-02 covers adjacent stale-toolchain fixes: `release-please.yml` publish-hex pin bump, README.md CI matrix sentence, CONTRIBUTING.md 4th bullet, D-11 retirement in PROJECT.md/MILESTONES.md/v1.7-MILESTONE-AUDIT.md
- No blockers — ci.yml reshape complete and verified

---
*Phase: 60-otp-matrix-reshape-nightly-schedule*
*Completed: 2026-07-03*
