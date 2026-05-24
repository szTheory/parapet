---
phase: 17-recovery-depth-runbook-templates
plan: "01"
subsystem: runbook-dsl
tags: [runbook, warning, dsl, workbench-contract, operator-ui, tdd]
dependency_graph:
  requires: []
  provides: [warning-dsl-foundation]
  affects: [runbook-templates, operator-ui]
tech_stack:
  added: []
  patterns: [surgical-macro-addition, explicit-field-projection, eex-heex-amber-block]
key_files:
  created: []
  modified:
    - lib/parapet/runbook.ex
    - lib/parapet/operator/workbench_contract.ex
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - test/parapet/runbook_test.exs
    - test/parapet/operator/workbench_contract_test.exs
decisions:
  - "warning: renders regardless of step.state (unlike guidance: which is state-gated) — a step in any state may carry a precondition or impact advisory"
  - "String key Map.get(step, \"warning\") used in projection because stringify_keys/1 normalizes atom keys before projection — handles both __runbook_schema__() output and DB round-trip"
  - "amber (bg-amber-50 border-amber-100 text-amber-800) for step.warning — distinct from blue guidance block and red runtime preview_panel warnings"
  - "@doc added to step/2 in same commit as DSL change to keep documented options == implemented keys (D-12)"
metrics:
  duration_minutes: 2
  completed_date: "2026-05-24"
  tasks_completed: 3
  files_modified: 5
---

# Phase 17 Plan 01: Warning DSL Foundation Summary

JWT-style one-liner: Added `warning:` as the 12th key in the `step/2` macro step map, threaded it through the `WorkbenchContract.derive_runbook_steps/3` projection (string key `"warning"` after `stringify_keys/1`), and rendered it as an amber `bg-amber-50` block in the `runbook_card` between the guidance block and targeting_hints block — gated by two TDD regression layers (schema + projection).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Failing test: warning: in schema | c951974 | test/parapet/runbook_test.exs |
| 1 (GREEN) | Add warning: to step/2 macro + @doc | f543c6e | lib/parapet/runbook.ex |
| 2 (RED) | Failing test: warning: in projection | 47b661b | test/parapet/operator/workbench_contract_test.exs |
| 2 (GREEN) | Thread warning: through WorkbenchContract | 8da3667 | lib/parapet/operator/workbench_contract.ex |
| 3 | Render amber warning block in runbook_card | e787a42 | priv/templates/parapet.gen.ui/operator_components.ex.eex |

## What Was Built

### Task 1: warning: key in step/2 macro + @doc (TDD)

Added `warning: unquote(opts)[:warning]` to the `@steps` map inside `defmacro step(id, opts)` at `lib/parapet/runbook.ex` after the `guidance:` line. The resulting step map now has 12 keys. Added `@doc` immediately before `defmacro step(id, opts)` documenting all accepted options including the new `warning:` option (D-12 compliance — documented in same commit as DSL addition so `mix verify.public_api` stays green).

`__before_compile__/1` was not modified — `Macro.escape(steps)` at line 60 already captures the full step map automatically.

Schema-layer regression test: added `warning: "Check logs before proceeding."` to the `:investigate` step in `DummyRunbook` and asserted `investigate_step.warning == "Check logs before proceeding."`.

### Task 2: warning: through WorkbenchContract projection (TDD)

Added `warning: Map.get(step, "warning"),` to the explicit projection map in `derive_runbook_steps/3` at `lib/parapet/operator/workbench_contract.ex` immediately after `guidance: Map.get(step, "guidance"),` and before `state: state,`. Uses the string key `"warning"` because `stringify_keys/1` at line 115 normalizes atom keys to strings before projection — correct for both `__runbook_schema__()` output (atom keys) and DB round-trip data (string keys).

Projection-layer regression test: added `warning: "test warning text"` to the step-1 fixture in the WorkbenchContract projection test and asserted `s1.warning == "test warning text"` after `derive/3`.

### Task 3: Amber warning block in runbook_card

Inserted a new warning render block in `priv/templates/parapet.gen.ui/operator_components.ex.eex` between the guidance block (lines 293–297) and the targeting_hints block. The block renders when `step.warning` is truthy, regardless of `step.state`. Uses amber Tailwind styling (`bg-amber-50 border border-amber-100 rounded text-xs text-amber-800 mt-2 p-2`) to distinguish from the blue guidance block and the red runtime `preview_panel` warnings (`preview.data["warnings"]`). The preview_panel warnings block (lines 361–370) was not modified (D-03).

## Verification Results

- `mix test test/parapet/runbook_test.exs test/parapet/operator/workbench_contract_test.exs` — 13 tests, 0 failures
- `mix test` (full suite) — 307 tests, 0 failures
- `mix verify.public_api` — passes (step/2 documented with warning: option, D-12)

## Deviations from Plan

### Pre-existing State Note (not a deviation)

The plan's acceptance criteria for Task 3 stated `grep -c 'preview.data["warnings"]' ... == 1`. The pre-existing file had 2 occurrences (the `if` condition on line 367 and the `for` loop on line 371, both within the same preview_panel block). This was a pre-existing count in the file before any changes — the preview_panel block itself was not modified (D-03 satisfied). The relevant invariant (the preview_panel block is unchanged) holds.

No other deviations — plan executed exactly as written.

## TDD Gate Compliance

Both TDD tasks followed the RED/GREEN pattern:

1. `test(17-01)` commit (RED gate) — c951974 (schema layer), 47b661b (projection layer)
2. `feat(17-01)` commit (GREEN gate) — f543c6e (schema layer), 8da3667 (projection layer)
3. No REFACTOR step needed (code was minimal and clean as written)

## Known Stubs

None — all fields are fully wired from DSL through projection to UI render.

## Threat Flags

No new security-relevant surfaces introduced. The `warning:` field is a static compile-time string literal (not user input), rendered via Phoenix HEEx auto-escaping (T-17-03: accepted). Schema and projection regression tests mitigate T-17-01 and T-17-02. D-12 compliance mitigates T-17-04.

## Self-Check: PASSED

Files exist:
- lib/parapet/runbook.ex: FOUND (contains `warning: unquote(opts)[:warning]`)
- lib/parapet/operator/workbench_contract.ex: FOUND (contains `warning: Map.get(step, "warning")`)
- priv/templates/parapet.gen.ui/operator_components.ex.eex: FOUND (contains `step.warning`)
- test/parapet/runbook_test.exs: FOUND (contains `warning: "Check logs before proceeding."`)
- test/parapet/operator/workbench_contract_test.exs: FOUND (contains `s1.warning == "test warning text"`)

Commits exist:
- c951974: FOUND (test RED: schema layer)
- f543c6e: FOUND (feat GREEN: step/2 macro + @doc)
- 47b661b: FOUND (test RED: projection layer)
- 8da3667: FOUND (feat GREEN: WorkbenchContract projection)
- e787a42: FOUND (feat: runbook_card amber warning block)
