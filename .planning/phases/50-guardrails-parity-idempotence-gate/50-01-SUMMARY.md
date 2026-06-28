---
phase: 50-guardrails-parity-idempotence-gate
plan: "01"
subsystem: test-apparatus
tags: [guard, parity, palette, motion, test, eex-fix]
dependency_graph:
  requires: [44-01, 44-02, 44-03, 44-04, 45-01, 45-02, 45-03, 45-04, 46-01, 46-02, 46-03, 46-04, 47-01, 47-02, 47-03, 49-01, 49-02, 49-03]
  provides: [GUARD-03, GUARD-04, GUARD-05]
  affects: [operator_ui_parity_test, operator_ui_palette_gate_test, operator_ui_motion_test, operator_ui_paths, operator_components_template]
tech_stack:
  added: []
  patterns: [Igniter.Test generator invocation, Code.format_string! normalization, MapSet allowlist gate, tolerant regex for CSS values]
key_files:
  created:
    - test/parapet/operator_ui_parity_test.exs
    - test/parapet/operator_ui_palette_gate_test.exs
    - test/parapet/operator_ui_motion_test.exs
    - test/support/operator_ui_paths.ex
  modified:
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - brandbook/notes/operator-audit-matrix.md
decisions:
  - "D-03: Fix <%#- (build-time, renders to empty) -> <%%# (EEx escape, renders to <%#) at lines 1428/1442 of operator_components.ex.eex to reproduce mirror comments"
  - "GUARD-03: Normalize both sides through Code.format_string! (not AST-compare) to preserve comments and catch D-03 drift"
  - "GUARD-04: Fail-closed gate sourced live from tokens.css; 5 exceptions declared with audit-matrix rationale; augments existing class-denylist"
  - "GUARD-05: Tolerant regex (not literal string) for easing curve to handle template vs tokens.css leading-zero disagreement"
metrics:
  duration: "~3 minutes"
  completed: "2026-06-28"
  tasks: 3
  files: 6
status: complete
---

# Phase 50 Plan 01: Guardrails Apparatus (GUARD-03/04/05) Summary

**One-liner:** GUARD-03 byte-parity (Igniter+Code.format_string!), GUARD-04 fail-closed hex gate (tokens.css live-parse + 5 documented exceptions), GUARD-05 tolerant easing regex + dual reduced-motion zeroing; D-03 EEx comment defect fixed.

## What Was Built

Three new async test files locking the operator UI built in phases 44–49 against silent regression, plus the shared `OperatorUIPaths` path helper and a fix for the generator-template comment defect (D-03) that GUARD-03 exists to catch.

### Task 1: D-03 template fix + OperatorUIPaths helper

Fixed `priv/templates/parapet.gen.ui/operator_components.ex.eex` at lines 1428 and 1442: replaced `<%#-` (EEx build-time comment, renders to empty string) with `<%%#` (EEx escape, renders to `<%#` in output). This ensures a fresh `mix parapet.gen.ui` reproduces the D-07/D-08 WCAG-1.4.1 rationale comments byte-identical to the committed demo mirror.

Created `test/support/operator_ui_paths.ex` (`Parapet.TestSupport.OperatorUIPaths`) with three zero-arity functions (`component_paths/0`, `live_template_paths/0`, `detail_template_paths/0`) providing the single-source-of-truth for the six template↔mirror file paths consumed by all three new test files.

### Task 2: GUARD-03 parity test

`test/parapet/operator_ui_parity_test.exs` drives the real Igniter generator (`test_project(app_name: :demo_app) |> Ui.igniter()`) and normalizes both sides through `Code.format_string!/1` before asserting equality — preserving comments (unlike AST-compare which discards them). Covers all three pairs: `operator_components`, `operator_live`, `operator_detail_live`. On mismatch, names the pair, shows the first divergent line + line number, and ends with the exact remediation string. `try/rescue` catches parse errors as named parity failures.

### Task 3: GUARD-04 + GUARD-05 + audit matrix exceptions

**GUARD-04** (`test/parapet/operator_ui_palette_gate_test.exs`): Parses `brandbook/tokens/tokens.css` live at test time, asserts ≥ 31 hexes (fail-closed), declares 5 documented `@palette_exceptions` (all sourced from the audit matrix, no bare inline literals), then scans all three template pairs for any `#rrggbb` literal not in `allowlist ∪ exceptions`.

**GUARD-05** (`test/parapet/operator_ui_motion_test.exs`): Asserts the brand easing curve via `~r/cubic-bezier\(\s*0?\.2\s*,\s*0\s*,\s*0\s*,\s*1\s*\)/` (whitespace/leading-zero-tolerant — template and tokens.css disagree on `(.2, ...)` vs `(0.2, ...)`). Also asserts BOTH `--motion-fast: 0ms` AND `--motion-base: 0ms` are zeroed under `prefers-reduced-motion` (existing test only covered `--motion-fast`).

**Audit matrix**: Documented four new GUARD-04 exception entries (`#A8D0DE`, `#1A5066`, `#556B77`, `#8C2E27`) in `brandbook/notes/operator-audit-matrix.md` with per-entry rationale and contrast notes, completing the five-exception set (all five now documented).

## Verification

- `mix test test/parapet/operator_ui_parity_test.exs test/parapet/operator_ui_palette_gate_test.exs test/parapet/operator_ui_motion_test.exs` — 5 tests, 0 failures
- `mix compile --warnings-as-errors` — clean
- `mix format --check-formatted` — clean for all new/modified test files and support module

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All test files are fully wired with real file reads and real generator invocation.

## Threat Flags

None. No new runtime attack surface introduced. The fail-closed `assert MapSet.size(allowlist) >= 31` mitigates T-50-01 (allowlist parse tampering). The `Code.format_string!` normalization (preserving comments, rejecting AST-compare) mitigates T-50-02. Exception hexes are sourced only from the documented audit-matrix section (T-50-03 mitigated).

## Self-Check: PASSED

- test/parapet/operator_ui_parity_test.exs — FOUND
- test/parapet/operator_ui_palette_gate_test.exs — FOUND
- test/parapet/operator_ui_motion_test.exs — FOUND
- test/support/operator_ui_paths.ex — FOUND
- brandbook/notes/operator-audit-matrix.md — FOUND (4 new exception sections added)
- fb8627f (D-03 fix + OperatorUIPaths) — FOUND
- 817b263 (GUARD-03 parity test) — FOUND
- 8ec0d3b (GUARD-04 gate + GUARD-05 motion + audit matrix) — FOUND
