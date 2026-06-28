---
phase: 49-stress-fixtures-seed-coverage
plan: "03"
subsystem: testing
tags: [elixir, bash, screenshot, headless-chrome, gallery, gallery-route, dark-mode, mobile]

# Dependency graph
requires:
  - phase: 49-stress-fixtures-seed-coverage
    plan: "01"
    provides: "RED static grep pin asserting >=4 lines with both 'capture' and '_gallery' in capture_operator_ui_screenshots.sh"
  - phase: 49-stress-fixtures-seed-coverage
    plan: "02"
    provides: "DemoSeedScenarios with stress scenario for FIXTURE-05 coverage"
provides:
  - "Four /parapet/_gallery capture lines (desktop+mobile, light+dark) in the canonical operator audit-capture script"
  - "GALLERY-02 script coverage: static grep pin GREEN"
  - "FIXTURE-05 stress scenario coverage across desktop+mobile and light+dark"
affects: [phase-50-baselines, operator-audit-workflow]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tall window sizes for scrolling gallery captures: 1440,5200 (desktop) / 414,7600 (mobile)"
    - "Reuse capture() helper with ?parapet_theme= for gallery route — no new quoting or theming seams"
    - "Gallery renders from hardcoded fixtures (no DB seed required — server-up only)"

key-files:
  created: []
  modified:
    - examples/demo_app/scripts/capture_operator_ui_screenshots.sh

key-decisions:
  - "Use 1440,5200 desktop and 414,7600 mobile window sizes (matching gallery_preview.sh) to avoid clipping the long scrolling gallery (RESEARCH Pitfall 6)"
  - "Four gallery capture lines placed after operator-page captures and before the final ls (plan-specified insertion point)"
  - "No rasters committed; PNG output stays in parameterized OUTPUT_DIR (D-09)"

patterns-established:
  - "Gallery captures reuse the capture() helper with ?parapet_theme= branching — consistent quoting and theming across all routes"

requirements-completed: [FIXTURE-05, GALLERY-02]

coverage:
  - id: D1
    description: "capture_operator_ui_screenshots.sh extended with four /parapet/_gallery captures — desktop-light, desktop-dark, mobile-light, mobile-dark — using tall window sizes (1440,5200 / 414,7600) reusing the capture() helper (GALLERY-02 / FIXTURE-05)"
    requirement: GALLERY-02
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#GALLERY-02 script: capture_operator_ui_screenshots.sh covers /parapet/_gallery 4 times (desktop+mobile, light+dark)"
        status: pass
    human_judgment: false
  - id: D2
    description: "bash -n syntax check passes on the extended capture script"
    requirement: GALLERY-02
    verification:
      - kind: other
        ref: "bash -n examples/demo_app/scripts/capture_operator_ui_screenshots.sh"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-06-28
status: complete
---

# Phase 49 Plan 03: Capture Script Gallery Extension Summary

**Four /parapet/_gallery captures (desktop+mobile, light+dark) added to the canonical operator audit-capture script, flipping the 49-01 static grep pin GREEN (GALLERY-02)**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-28T20:49:58Z
- **Completed:** 2026-06-28T20:55:00Z
- **Tasks:** 2 (Task 1: script extension; Task 2: grep pin confirmation — no file change needed)
- **Files modified:** 1

## Accomplishments

- Added four `/parapet/_gallery` capture lines to `capture_operator_ui_screenshots.sh` between the operator-page captures and the final `ls`
- Used tall window sizes `1440,5200` (desktop) and `414,7600` (mobile) matching `gallery_preview.sh` to avoid clipping the long scrolling gallery (RESEARCH Pitfall 6)
- Reused the existing `capture()` helper with `?parapet_theme=` convention — no new quoting, no new theming/env seam
- `bash -n` syntax check passes; all 25 operator smoke tests pass (0 failures)
- Static grep pin GALLERY-02 now GREEN: script contains 4 lines with both `capture` and `_gallery`

## Task Commits

1. **Task 1: Add four /parapet/_gallery captures to canonical script** — `3d5167d` (feat)
2. **Task 2: Confirm static grep pin flips green** — no file change; verified by running `mix test test/demo_app/operator_smoke_test.exs` (25 tests, 0 failures)

## Files Created/Modified

- `/Users/jon/projects/parapet/examples/demo_app/scripts/capture_operator_ui_screenshots.sh` — extended with 8-line GALLERY-02 block (comment + 4 capture lines + blank line), inserted before `ls -1 "$OUTPUT_DIR"/*.png`

## Decisions Made

- The four gallery capture lines were present in the working tree at executor start (pre-work from plan authoring or prior session). Confirmed correct form, ran `bash -n` and the full smoke test suite, then committed atomically.
- Tall window sizes from `gallery_preview.sh` (:130-133) used as-is: `1440,5200` desktop, `414,7600` mobile — both values documented in RESEARCH.md Pitfall 6 and in the plan action spec.
- Task 2 (grep pin confirmation) required no file change — the test passed after Task 1's commit; documented as a zero-change verification task.

## Deviations from Plan

None — plan executed exactly as written. The four gallery capture lines satisfy the test's predicate (both `capture` and `_gallery` on the same line). All planned must_haves confirmed:
- gallery_preview.sh untouched (D-08)
- No rasters committed (D-09)
- No new theming/env seam (capture() helper reused)

## Issues Encountered

None. The script change was straightforward; the static grep pin confirmed GREEN on first run.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The capture script is an operator-run local tool (not a CI or production artifact). The four gallery capture lines reuse the existing `capture()` helper with already-quoted `$CHROME_BIN` and `?parapet_theme=` branching — T-49-03 (Tampering / bash env interpolation) mitigated as planned.

## Next Phase Readiness

- Phase 49 is now complete: all three plans executed (RED scaffold → seed scenarios → capture script extension)
- All fixture-existence pins GREEN (49-02), static grep pin GREEN (49-03)
- Phase 50: operator can run the extended script against a PARAPET_DEMO_SCENARIO=stress-seeded DB to produce 15 PNGs (11 operator pages + 4 gallery) into tmp; committed baselines/manifest are Phase 50 scope (D-09)
- No blockers

---
*Phase: 49-stress-fixtures-seed-coverage*
*Completed: 2026-06-28*
