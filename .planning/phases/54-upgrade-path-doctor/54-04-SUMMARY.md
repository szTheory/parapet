---
phase: 54-upgrade-path-doctor
plan: "04"
subsystem: testing
tags: [elixir, exunit, ecto, postgres, schema-prefix, upgrade-path]

requires:
  - phase: 54-03
    provides: mix parapet.gen.schema.move task (installer/generator source files scanned by the fitness fn)
  - phase: 54-01
    provides: mix parapet.doctor schema check (context for UPG-05 guard)
  - phase: 52-propagation-proof-guards-ci-dual-prefix-matrix
    provides: ConcurrencyCase + dual-prefix CI matrix that this plan rides

provides:
  - UPG-01 Track A pin — describe block in prefix_propagation_test.exs proving schema_prefix nil emits bare unqualified SQL
  - UPG-05 fitness function — regex guard preventing installer/generators from ever auto-chaining schema-move
  - UPG-05 default-prefix pin — resolve_prefix(nil, nil) == {:ok, "parapet"} literal assertion

affects:
  - phase 55 demo app upgrade docs (references Track A as the documented opt-in path)
  - phase 56 contract and release hardening (UPG-01 + UPG-05 are part of the done-criteria audit)

tech-stack:
  added: []
  patterns:
    - "Compile-time module-attribute guard: if is_nil(@prefix) do / describe ... end — makes a test block a no-op on one CI leg and load-bearing proof on the other (D-19)"
    - "Regex fitness function cloning schema_prefix_guard_test shape: glob explicit file list → line-scan → assert offenders==[] with teaching message (D-20)"

key-files:
  created:
    - test/parapet/upgrade_never_forces_move_test.exs
  modified:
    - test/parapet/spine/prefix_propagation_test.exs

key-decisions:
  - "Guarded the Track A describe block with `if is_nil(@prefix)` at the module level (not inside a test-body conditional) so the entire describe block is a no-op on the parapet leg — matching the existing else-branch pattern at lines 39-42 (D-19)"
  - "Added `import Ecto.Query` to prefix_propagation_test.exs to support the `from` macro in the Track A to_sql proof — the existing tests only called helpers that return Ecto queries internally"
  - "Scanned only explicit file paths in the fitness fn (not a wildcard) to exclude parapet.gen.schema.move.ex itself, which legitimately names the move module (D-20)"
  - "Dual pattern in @forbidden_move_patterns: dotted atom form (parapet.(gen.)?schema.move) AND fully-qualified module name (Mix.Tasks.Parapet.Gen.Schema.Move) — catches both task invocation and module aliasing"

patterns-established:
  - "Track A nil-leg guard pattern: bind @prefix = Schema.__prefix__() at module top; wrap entire describe block in `if is_nil(@prefix) do ... end`"
  - "UPG-05 fitness fn shape: @installer_files explicit list + @forbidden_move_patterns + for comprehension + assert offenders==[] with format_move_guard_failure/1 teaching message"

requirements-completed: [UPG-01, UPG-05]

coverage:
  - id: D1
    description: "UPG-01 Track A to_sql proof — refute schema qualifier present, assert bare parapet_incidents table name on nil CI leg"
    requirement: UPG-01
    verification:
      - kind: integration
        ref: "test/parapet/spine/prefix_propagation_test.exs#UPG-01 Track A: schema_prefix nil emits unprefixed SQL to_sql carries a bare unqualified table name and no schema qualifier"
        status: pass
    human_judgment: false
  - id: D2
    description: "UPG-01 Track A write-path round-trip — Ecto.get_meta(incident, :prefix) == nil + green read-back via Evidence.create_incident on nil CI leg"
    requirement: UPG-01
    verification:
      - kind: integration
        ref: "test/parapet/spine/prefix_propagation_test.exs#UPG-01 Track A: schema_prefix nil emits unprefixed SQL write-path round-trip: get_meta prefix is nil + read-back succeeds"
        status: pass
    human_judgment: false
  - id: D3
    description: "UPG-05 installer/generator fitness fn — regex scan of parapet.install.ex, parapet.gen.spine.ex, parapet.gen.archive_indexes.ex asserts no move-task reference"
    requirement: UPG-05
    verification:
      - kind: unit
        ref: "test/parapet/upgrade_never_forces_move_test.exs#UPG-05: installer and gen tasks never reference the schema-move task (D-17, D-20)"
        status: pass
    human_judgment: false
  - id: D4
    description: "UPG-05 default-prefix pin — resolve_prefix(nil, nil) == {:ok, 'parapet'} asserts new-install default literal"
    requirement: UPG-05
    verification:
      - kind: unit
        ref: "test/parapet/upgrade_never_forces_move_test.exs#UPG-05: resolve_prefix(nil, nil) == {:ok, \"parapet\"} (default for new installs, D-20)"
        status: pass
    human_judgment: false

duration: 4min
completed: "2026-07-01"
status: complete
---

# Phase 54 Plan 04: UPG-01 Track A + UPG-05 Fitness Function Summary

**Track A nil-leg proof (to_sql bare table name + get_meta nil round-trip) and UPG-05 installer fitness function pinning the "no auto-migrate" contract with a teaching failure message**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-01T18:28:34Z
- **Completed:** 2026-07-01T18:32:59Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Extended `prefix_propagation_test.exs` with a `describe "UPG-01 Track A"` block guarded by `if is_nil(@prefix)` — fires only on the nil CI leg, no-op on the parapet leg; two assertions: bare-table to_sql proof and live write-path round-trip via `Evidence.create_incident`
- Created `test/parapet/upgrade_never_forces_move_test.exs` — regex fitness function scanning the three installer/generator files for forbidden move-task references (goes red the day someone wires the move into the installer), plus `resolve_prefix(nil, nil) == {:ok, "parapet"}` default-prefix pin
- All four new test cases green on BOTH CI legs: nil leg (7 tests in prefix_propagation, 2 in upgrade_never_forces_move) and parapet leg (5 tests in prefix_propagation — Track A no-op, 2 in upgrade_never_forces_move)
- Added `import Ecto.Query` to `prefix_propagation_test.exs` to support the `from` macro in the Track A to_sql assertion

## Task Commits

1. **Task 1: Add UPG-01 Track A pin to prefix_propagation_test.exs** - `b445fd5` (feat)
2. **Task 2: UPG-05 regex fitness function + default-prefix pin** - `bb8f6a9` (feat)

## Files Created/Modified

- `test/parapet/spine/prefix_propagation_test.exs` - Added `import Ecto.Query` and `describe "UPG-01 Track A"` block (42 lines inserted) guarded by `if is_nil(@prefix)`
- `test/parapet/upgrade_never_forces_move_test.exs` - New file: UPG-05 fitness function + resolve_prefix default pin (140 lines)

## Decisions Made

- Used `if is_nil(@prefix) do / describe ... end` at the module level rather than an `if @prefix` inside test bodies — this matches the plan's spec and the existing else-branch pattern in the to_sql tests, and makes the entire describe block a compile-time-level no-op on the parapet leg (consistent with D-19)
- Added `import Ecto.Query` as a deviation from the existing file — the existing tests use helper functions that return Ecto queries internally; the Track A to_sql test needs the `from` macro directly. This is a 1-line addition, not a structural change
- Used two forbidden patterns in the fitness function (dotted atom form AND fully-qualified module name) to catch both invocation-style (`parapet.gen.schema.move`) and alias-style (`Mix.Tasks.Parapet.Gen.Schema.Move`) references

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added `import Ecto.Query` to prefix_propagation_test.exs**

- **Found during:** Task 1 (Track A to_sql proof)
- **Issue:** The plan's code example uses `from(i in Incident, select: i.id)` but the existing test module had no `import Ecto.Query` — the `from` macro would not be in scope
- **Fix:** Added `import Ecto.Query` after the `use` line; consistent with how all other ConcurrencyCase tests that use `from` handle this (e.g., `executor_concurrency_test.exs`, `claim_service_test.exs`)
- **Files modified:** `test/parapet/spine/prefix_propagation_test.exs`
- **Verification:** Tests compiled and ran green; 7 tests on nil leg, 5 tests on parapet leg
- **Committed in:** b445fd5 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The `import Ecto.Query` addition is necessary for the to_sql proof to compile. No scope creep.

## Issues Encountered

- Local compilation required explicit `MIX_ENV=test mix compile --force` under each PARAPET_SCHEMA_PREFIX value before running tests — the `compile_env` check fails if the runtime value differs from the compile-time-frozen value. This is expected behavior (CI uses `mix compile --force` per leg in its matrix). Not a bug; documented as a local dev workflow note.

## Known Stubs

None — both test files are complete with no placeholder assertions or stub data.

## Threat Flags

None — these are test-only files; no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries.

## Next Phase Readiness

- Phase 54 is now complete (all 4 plans executed)
- UPG-01 + UPG-05 are pinned; DOCTOR-01 (54-01), UPG-02+UPG-03 (54-02), UPG-04 (54-03) were pinned in prior plans
- Ready for Phase 55: Demo App & Upgrade Docs (DOC-01, DOC-02, SAFE-03)

## Self-Check: PASSED

- FOUND: test/parapet/spine/prefix_propagation_test.exs
- FOUND: test/parapet/upgrade_never_forces_move_test.exs
- FOUND: .planning/phases/54-upgrade-path-doctor/54-04-SUMMARY.md
- FOUND commit: b445fd5 (Task 1)
- FOUND commit: bb8f6a9 (Task 2)

---

*Phase: 54-upgrade-path-doctor*
*Completed: 2026-07-01*
