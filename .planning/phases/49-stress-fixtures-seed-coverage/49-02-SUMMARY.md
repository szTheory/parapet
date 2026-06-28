---
phase: 49-stress-fixtures-seed-coverage
plan: "02"
subsystem: demo-seed
tags: [elixir, phoenix, liveview, ecto, seed, fixtures, tdd, smoke-test]

# Dependency graph
requires:
  - phase: 49-01
    provides: RED scaffold — FIXTURE-01..05 pins and registry pin that this plan flips GREEN
provides:
  - "Five new compiled seed scenarios (long_string, empty, max_items, mixed_status, stress)"
  - "DemoApp.DemoSeedScenarios compiled into the application (no longer a priv/repo script)"
  - "All FIXTURE-01..05 fixture-existence pins GREEN"
affects: [49-03-capture-script]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Move demo seed module from priv/repo/*.exs (script) to lib/demo_app/*.ex (compiled) so it is available in the Ecto sandbox"
    - "stress = union pattern: seed/1 calls long_string_incident/0 + max_items_dense/0 + mixed_status_spread/0"
    - "Escalation diversity via helper reuse: checkout_webhook_failures/stalled_async_executor/signup_email_resolved/retry_storm each derive a distinct escalation status without new mechanics"

key-files:
  created:
    - examples/demo_app/lib/demo_app/demo_seed_scenarios.ex
  modified:
    - examples/demo_app/priv/repo/demo_seed_scenarios.exs
    - examples/demo_app/priv/repo/seeds.exs
    - test/parapet/operator_ui_demo_contract_test.exs

key-decisions:
  - "Move module to lib/demo_app/demo_seed_scenarios.ex (compiled) — required to satisfy RED pins; priv/repo/*.exs is Code.require_file'd only at `mix run` time, not compiled into the app"
  - "stress = long_string_incident() + max_items_dense() + mixed_status_spread() — union via helper composition, no duplication (D-06)"
  - "max_items seeds 35 active incidents (>30 page-boundary with margin, ~12ms seed time)"
  - "mixed_status reuses 4 existing escalation helpers for escalation diversity; adds idle bare incident + 5 open ActionItems (one per kind) for Actions-page coverage"
  - "Update operator_ui_demo_contract_test.exs @seed_scenarios_path to point to the new compiled .ex location (Rule 1 fix — old path assertion would fail against empty placeholder)"

requirements-completed: [FIXTURE-01, FIXTURE-02, FIXTURE-03, FIXTURE-04, FIXTURE-05]

coverage:
  - id: FIXTURE-01
    description: "seed('long_string') creates ≥1 incident with title >60 chars, long unbroken machine-shaped fields"
    requirement: FIXTURE-01
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-01: seed('long_string') seeds at least one incident with a title >60 chars"
        status: pass
    human_judgment: false
  - id: FIXTURE-02
    description: "seed('empty') produces 0 incidents and 0 action items"
    requirement: FIXTURE-02
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-02: seed('empty') produces 0 incidents and 0 action items"
        status: pass
    human_judgment: false
  - id: FIXTURE-03
    description: "seed('max_items') seeds >30 active incidents (crosses page boundary)"
    requirement: FIXTURE-03
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-03: seed('max_items') seeds >30 active incidents (crosses page boundary)"
        status: pass
    human_judgment: false
  - id: FIXTURE-04
    description: "seed('mixed_status') covers all three incident states and has open action items"
    requirement: FIXTURE-04
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-04: seed('mixed_status') covers all three incident states and has open action items"
        status: pass
    human_judgment: false
  - id: FIXTURE-05
    description: "seed('stress') seeds ≥1 active incident; all five new names in scenarios/0"
    requirement: FIXTURE-05
    verification:
      - kind: unit
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FIXTURE-05: seed('stress') seeds at least one active (open/investigating) incident"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-06-28
status: complete
---

# Phase 49 Plan 02: Seed Implementation (GREEN) Summary

**Five new compiled seed scenarios flip FIXTURE-01..05 pins from RED to green; module promoted from priv/repo script to compiled lib module**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-06-28T19:45:39Z
- **Completed:** 2026-06-28T19:49:34Z
- **Tasks:** 3 (all in one atomic commit — implementation touches same file set)
- **Files modified:** 4

## Accomplishments

- **Task 1 (empty + long_string):** Added `seed("empty")` (`:ok` no-op before typo-guard) and `seed("long_string")` with `long_string_incident/0` helper; incident has >100-char machine-shaped title, unbroken description/correlation_key, long runbook step labels/descriptions, deep query-string external_link URL, and an open ActionItem with long machine-shaped external_id + title. FIXTURE-02 + FIXTURE-01 pins GREEN.
- **Task 2 (max_items + mixed_status):** `seed("max_items")` calls `max_items_dense/0` which loops `Enum.each(1..35, ...)` to create 35 active incidents (31 open, 4 investigating via `rem(n,3)==0`), dense action items on every 5th incident, long timeline on first. `seed("mixed_status")` calls `mixed_status_spread/0` which reuses all four existing escalation helpers (checkout_webhook_failures → requested, stalled_async_executor → suppressed, signup_email_resolved → executed, retry_storm → short-circuited) plus adds a bare idle open incident and creates one open ActionItem per kind (5 total: exact_follow_up, suppressed_delivery, stalled_workflow, orphaned_callback, dead_letter). FIXTURE-03 + FIXTURE-04 pins GREEN.
- **Task 3 (stress):** `seed("stress")` calls `long_string_incident()`, `max_items_dense()`, `mixed_status_spread()` in sequence — union composition, no duplication. Guarantees ≥1 active incident via max_items. FIXTURE-05 active-incident pin GREEN.
- **Final test run:** 25 tests, 1 failure (expected — GALLERY-02 script grep pin stays RED, 49-03 scope)

## Task Commits

1. **Tasks 1+2+3: implement five new seed scenarios + promote module to compiled** — `12ca922` (feat)

## Files Created/Modified

- `/Users/jon/projects/parapet/examples/demo_app/lib/demo_app/demo_seed_scenarios.ex` — new compiled module; extended @scenarios with 5 new names; 5 new seed/1 clauses + 3 new private helpers (long_string_incident, max_items_dense, mixed_status_spread); all existing helpers untouched
- `/Users/jon/projects/parapet/examples/demo_app/priv/repo/demo_seed_scenarios.exs` — replaced with tombstone comment directing to new location
- `/Users/jon/projects/parapet/examples/demo_app/priv/repo/seeds.exs` — removed Code.require_file (module now compiled)
- `/Users/jon/projects/parapet/test/parapet/operator_ui_demo_contract_test.exs` — updated @seed_scenarios_path to point to new .ex file (Rule 1 fix)

## Decisions Made

- Module promotion to `lib/demo_app/demo_seed_scenarios.ex` is the necessary architectural step — `priv/repo/*.exs` files are scripts (`Code.require_file`'d only at `mix run` time), not compiled into the application supervision tree. Tests require `DemoApp.DemoSeedScenarios.seed/1` to be callable as a compiled module function inside the Ecto sandbox.
- `stress` composes helpers via function calls — no code duplication. Three-function body over 3 lines.
- `max_items_dense/0` uses `Enum.each(1..35, fn n -> ... end)` with a distinct `correlation_key` per incident (includes `:rand.uniform/1` suffix to guarantee uniqueness across repeated seeds in the same test run if needed).
- `mixed_status_spread/0` creates one open ActionItem per each of the 5 `@kinds` — attached to the idle incident so every kind shows up on the Actions page from a single anchor.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Promote DemoSeedScenarios from priv/repo script to compiled lib module**
- **Found during:** Task 1 execution — the 49-01 SUMMARY explicitly flagged this: "Plan 49-02 will add the module to a proper `.ex` file location so it is compiled and available in the sandbox"
- **Issue:** `priv/repo/demo_seed_scenarios.exs` is a script loaded only via `Code.require_file` in `seeds.exs` at `mix run` time. The demo app's `elixirc_paths(:test)` is `["test/support", "lib"]` — the `.exs` script is never compiled. Tests calling `DemoApp.DemoSeedScenarios.seed/1` fail with `UndefinedFunctionError` until the module is compiled.
- **Fix:** Created `examples/demo_app/lib/demo_app/demo_seed_scenarios.ex` with the full module (all existing helpers verbatim + 5 new scenarios + 3 new helpers). Replaced `priv/repo/demo_seed_scenarios.exs` with a tombstone. Removed `Code.require_file` from `seeds.exs`.
- **Files modified:** `lib/demo_app/demo_seed_scenarios.ex` (new), `priv/repo/demo_seed_scenarios.exs` (tombstone), `priv/repo/seeds.exs` (remove require)
- **Commit:** 12ca922

**2. [Rule 1 - Bug] Update operator_ui_demo_contract_test.exs @seed_scenarios_path**
- **Found during:** Full lib suite run after Task 1 commit
- **Issue:** `test/parapet/operator_ui_demo_contract_test.exs` had `@seed_scenarios_path "examples/demo_app/priv/repo/demo_seed_scenarios.exs"` and asserted the file contained `seed("response")` etc. After the move, the tombstone `.exs` file no longer contains those markers — test would fail.
- **Fix:** Updated `@seed_scenarios_path` to `"examples/demo_app/lib/demo_app/demo_seed_scenarios.ex"`. The new compiled module contains all required markers.
- **Files modified:** `test/parapet/operator_ui_demo_contract_test.exs`
- **Commit:** 12ca922 (same commit)

## Issues Encountered

- Pre-existing lib suite failure (unrelated): `Parapet.DocsPhase33Test` asserts README contains `"make up-auto"` — the README does not have that string. This failure exists before and after this plan's changes (confirmed by `git stash` + retest). Documented as pre-existing out-of-scope issue.

## Known Stubs

None — all five scenarios produce real seeded data. No placeholder text or empty-value stubs.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Changes are demo-only: a compiled seed module, an updated entrypoint script, and a test contract path update. `ActionItem.changeset/2` and `Parapet.Evidence.create_incident/1` validate all enum inclusions at insert time — changeset validation enforces `kind ∈ @kinds` and `state ∈ ["open","resolved"]`; `Incident` validates `state ∈ ["open","investigating","resolved"]`. All seed values are author-controlled, not user input. HEEx auto-escapes all rendered strings including long machine-shaped external_link URLs/IDs (T-49-02 accepted).

## Next Phase Readiness

- 49-03 must add four `capture + _gallery` lines to `capture_operator_ui_screenshots.sh` to flip the GALLERY-02 grep pin GREEN
- No blockers

---
*Phase: 49-stress-fixtures-seed-coverage*
*Completed: 2026-06-28*
