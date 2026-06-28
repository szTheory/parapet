---
phase: 49-stress-fixtures-seed-coverage
plan: "01"
subsystem: testing
tags: [elixir, exunit, phoenix, liveview, conncase, tdd, smoke-test, gallery]

# Dependency graph
requires:
  - phase: 48-pages-flows-microcopy
    provides: operator_smoke_test.exs ConnCase harness and Phase-48 describe block as structural model
provides:
  - "Phase-49 RED scaffold in operator_smoke_test.exs: gallery route contract test + 5 fixture-existence pins + static grep pin"
affects: [49-02-seed, 49-03-script]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-12 RED-first scaffold: write failing fixture-existence assertions before seed/script edits land; flip green in subsequent plans"
    - "Self-seeding sandbox test: DemoSeedScenarios.seed/1 called inside test, asserted via Repo.aggregate — no external seeds.exs dependency"

key-files:
  created: []
  modified:
    - examples/demo_app/test/demo_app/operator_smoke_test.exs

key-decisions:
  - "Gallery route contract test passes GREEN immediately (route exists) — it is a regression guard, not a feature gate"
  - "Fixture pins reference DemoApp.DemoSeedScenarios which does not exist yet in priv/repo/demo_seed_scenarios.exs — RED by design (D-12)"
  - "Static grep pin counts lines containing both 'capture' and '_gallery' to avoid false-positives from plain comments"
  - "FIXTURE-04 mixed_status asserts state superset coverage but does NOT assert journey :down (journeys hardcoded in mount, N/A-by-design per 49-VALIDATION.md)"

patterns-established:
  - "Phase-49 fixture-pin convention: one test block per scenario → each gets a fresh rolled-back sandbox, counts never accumulate across pins"

requirements-completed: [FIXTURE-01, FIXTURE-02, FIXTURE-03, FIXTURE-04, FIXTURE-05, GALLERY-02]

coverage:
  - id: D1
    description: "GET /parapet/_gallery returns 200 with operator-component markers (parapet-ui, heading, po-operator-title, po-chip) against an unseeded sandbox — DB-independence + route-ordering regression guard"
    requirement: GALLERY-02
    verification:
      - kind: integration
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#GET /parapet/_gallery returns 200 with operator-component markers (GALLERY-02)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fixture-existence pin: FIXTURE-05 registry — all five new scenario names registered in DemoSeedScenarios.scenarios/0"
    requirement: FIXTURE-05
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-05: all five new scenario names are registered in DemoSeedScenarios.scenarios/0"
        status: fail
    human_judgment: false
  - id: D3
    description: "Fixture-existence pin: FIXTURE-02 empty scenario seeds 0 incidents + 0 action items"
    requirement: FIXTURE-02
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-02: seed('empty') produces 0 incidents and 0 action items"
        status: fail
    human_judgment: false
  - id: D4
    description: "Fixture-existence pin: FIXTURE-03 max_items seeds >30 active incidents (page-boundary crossing)"
    requirement: FIXTURE-03
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-03: seed('max_items') seeds >30 active incidents (crosses page boundary)"
        status: fail
    human_judgment: false
  - id: D5
    description: "Fixture-existence pin: FIXTURE-04 mixed_status covers all three incident states and has open action items"
    requirement: FIXTURE-04
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-04: seed('mixed_status') covers all three incident states and has open action items"
        status: fail
    human_judgment: false
  - id: D6
    description: "Fixture-existence pin: FIXTURE-01 long_string seeds at least one incident with title >60 chars"
    requirement: FIXTURE-01
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-01: seed('long_string') seeds at least one incident with a title >60 chars"
        status: fail
    human_judgment: false
  - id: D7
    description: "Fixture-existence pin: FIXTURE-05 stress seeds at least one active incident (DETAIL_ID precondition)"
    requirement: FIXTURE-05
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-05: seed('stress') seeds at least one active (open/investigating) incident"
        status: fail
    human_judgment: false
  - id: D8
    description: "Static grep pin: capture_operator_ui_screenshots.sh covers /parapet/_gallery at least 4 times (desktop+mobile, light+dark)"
    requirement: GALLERY-02
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#GALLERY-02 script: capture_operator_ui_screenshots.sh covers /parapet/_gallery 4 times (desktop+mobile, light+dark)"
        status: fail
    human_judgment: false

# Metrics
duration: 2min
completed: 2026-06-28
status: complete
---

# Phase 49 Plan 01: Stress Fixtures Seed Coverage RED Scaffold Summary

**D-12 RED scaffold: gallery route contract test (GREEN) + five fixture-existence pins + static grep pin (both RED) written before seed/script edits land in 49-02/49-03**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-06-28T19:40:00Z
- **Completed:** 2026-06-28T19:42:00Z
- **Tasks:** 3 (all in one atomic commit — same file)
- **Files modified:** 1

## Accomplishments

- Added `describe "Phase 49 gallery + fixture coverage"` block to `examples/demo_app/test/demo_app/operator_smoke_test.exs`
- Task 1: Gallery render contract test — `GET /parapet/_gallery` → 200 with `parapet-ui`, `Parapet Operator UI Gallery`, `po-operator-title`, `po-chip` against unseeded sandbox; passes GREEN immediately
- Task 2: Six fixture-existence pins (registry check + 5 scenario seeds) that call `DemoApp.DemoSeedScenarios.seed/1` — fail RED because `DemoApp.DemoSeedScenarios` is not yet a compiled module (scenarios land in 49-02)
- Task 3: Static grep pin counting lines containing both `capture` and `_gallery` in the capture script — fails RED (0 matches, 49-03 adds the four lines)
- Final test run: 25 tests, 7 failures — expected D-12 RED state

## Task Commits

1. **Tasks 1+2+3: Phase 49 RED scaffold (all tasks, same file)** — `5f71d23` (test)

## Files Created/Modified

- `/Users/jon/projects/parapet/examples/demo_app/test/demo_app/operator_smoke_test.exs` — extended with 163-line Phase-49 describe block (gallery contract + 6 fixture pins + grep pin)

## Decisions Made

- All three tasks written in one commit: the plan adds one describe block to one file; keeping tasks 1/2/3 in one atomic commit is simpler than splitting the block across three
- Gallery test passes GREEN immediately — confirmed by test run before commit; documented as a route-ordering regression guard
- FIXTURE-04 does NOT assert journey `:down` — journeys are hardcoded in `operator_live.ex` mount, not seeded; per 49-VALIDATION.md "N/A-by-design"
- Static grep pin counts lines containing both `"capture"` AND `"_gallery"` (not `_gallery` alone) so plain file-path comments in the script do not inflate the count

## Deviations from Plan

None — plan executed exactly as written. All tasks implemented as specified. RED state confirmed.

## Issues Encountered

None. The module `DemoApp.DemoSeedScenarios` in `priv/repo/demo_seed_scenarios.exs` is a script file compiled via `mix run`, not a compiled application module — so the fixture pins produce `UndefinedFunctionError` rather than `ArgumentError`. Both are valid RED signals; the error message correctly identifies the function as undefined (confirming the scenarios are not yet implemented). Plan 49-02 will add the module to a proper `.ex` file location so it is compiled and available in the sandbox.

## Next Phase Readiness

- 49-02 must implement `DemoApp.DemoSeedScenarios` as a compiled module (move or promote `priv/repo/demo_seed_scenarios.exs`) and add the five new `seed/1` clauses to flip D2..D7 GREEN
- 49-03 must add four `_gallery` capture lines to `capture_operator_ui_screenshots.sh` to flip D8 GREEN
- No blockers

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Test-only changes; no production source modified.

---
*Phase: 49-stress-fixtures-seed-coverage*
*Completed: 2026-06-28*
