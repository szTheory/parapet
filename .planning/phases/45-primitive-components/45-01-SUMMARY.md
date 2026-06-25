---
phase: 45-primitive-components
plan: "01"
subsystem: test-harness
status: complete
tags: [tdd, red-scaffold, contrast, a11y, off-palette, motion, focus]
dependency_graph:
  requires: []
  provides: [45-02-PLAN.md, 45-03-PLAN.md, 45-04-PLAN.md]
  affects: [test/parapet/operator_ui_contrast_test.exs]
tech_stack:
  added: []
  patterns:
    - ExUnit @themes extension pattern (additive map entries + assert_contrast/5 calls)
    - File.read! + refute/assert content =~ pattern for string-search gating
key_files:
  created: []
  modified:
    - test/parapet/operator_ui_contrast_test.exs
decisions:
  - "Dark success button uses #3F5E28 bg / #EFF6E8 fg (inverted healthy-chip pair per 45-UI-SPEC.md) — not lighter values"
  - "COMP-02 gate added as assert disabled:opacity (not cursor-not-allowed) — covers the visual affordance; semantic attr check deferred to gallery audit"
  - "COMP-04 gate is refute border-amber- (prefix match) — catches all amber border utilities from escalation-chain markup"
  - "Both COMP-02 and COMP-04 gates are additive to the plan's original PATTERNS.md list per 45-01-PLAN.md must_haves truths"
metrics:
  duration: "4m"
  completed: 2026-06-25
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 45 Plan 01: TDD Red Scaffold — Contrast Gate & Off-Palette Gate Summary

Phase 45's Plan 01 wired the full Nyquist verification gate into the existing Phase 44 ExUnit harness before any remediation lands. All new assertions are RED until Plans 02/03 re-skin `operator_components.ex.eex`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend @themes with new button pairs + assert_contrast calls | 1660b1b | test/parapet/operator_ui_contrast_test.exs |
| 2 | Add off-palette / disabled / motion / focus / cursor gate to second test | 5e84ecb | test/parapet/operator_ui_contrast_test.exs |

## What Was Built

### Task 1 — @themes extension and contrast assertions

Added to the **light** `@themes` map (after `warning_button_fg: "#FFFFFF"`):
```elixir
primary_button_bg: "#101820", primary_button_fg: "#FFFFFF",
destructive_button_bg: "#B13A32", destructive_button_fg: "#FFFFFF",
success_button_bg: "#567236", success_button_fg: "#FFFFFF"
```

Added to the **dark** `@themes` map (after `warning_button_fg: "#101820"`):
```elixir
primary_button_bg: "#F8F4EC", primary_button_fg: "#2E3A42",
destructive_button_bg: "#B13A32", destructive_button_fg: "#FFFFFF",
success_button_bg: "#3F5E28", success_button_fg: "#EFF6E8"
```

Added inside the `for {theme, tokens} <- @themes do` loop:
```elixir
assert_contrast(theme, :primary_button, tokens.primary_button_fg, tokens.primary_button_bg, 4.5)
assert_contrast(theme, :destructive_button, tokens.destructive_button_fg, tokens.destructive_button_bg, 4.5)
assert_contrast(theme, :success_button, tokens.success_button_fg, tokens.success_button_bg, 4.5)
```

**Verification:** `mix test test/parapet/operator_ui_contrast_test.exs:66` → 1 test, 0 failures (green). All six new pairings (3 variants × 2 themes) meet WCAG AA 4.5:1.

### Task 2 — Off-palette / disabled / motion / focus / cursor gate

Added inside the `for path <- @component_paths do` block (after `"font-display: swap"` assertion):

```elixir
# COMP-08: off-palette class remediation complete
refute content =~ "bg-indigo-600"
refute content =~ "bg-indigo-500"
refute content =~ "bg-indigo-50 ring-indigo-100"
refute content =~ "bg-emerald-600"
refute content =~ "bg-purple-100"
refute content =~ "bg-violet-100"
refute content =~ "bg-blue-50"
refute content =~ "bg-teal-700"
refute content =~ "hover:ring-teal-700"
refute content =~ "#042f2e"

# MOTION-02: duration token used; no transition-all
refute content =~ "transition-all"
assert content =~ "duration-[--motion-fast]"

# COMP-06: po-focus on all controls
assert content =~ "po-focus"

# COMP-07: no raw badge color utilities
refute content =~ "bg-purple-100 text-purple-800"
refute content =~ "bg-violet-100 text-violet-800"
refute content =~ "bg-indigo-700"
refute content =~ "bg-violet-700"
refute content =~ "bg-slate-700"

# COMP-05: no spurious pointer cursor on stat cards
refute content =~ "cursor-pointer"

# COMP-02: disabled affordance wired in control_base()
assert content =~ "disabled:opacity"

# COMP-04: no raw amber border utilities in escalation-chain markup
refute content =~ "border-amber-"
```

**Verification:** `mix test test/parapet/operator_ui_contrast_test.exs` → 2 tests, 1 failure (second test). Failure is a `Refute with =~ failed` on `bg-indigo-600` — the violation still exists in `operator_components.ex.eex` pre-remediation. This is RED-as-expected.

## Requirements Coverage

| Req | Gate | Status |
|-----|------|--------|
| COMP-01 | assert_contrast for primary/destructive/success in both themes | Gated (first test green) |
| A11Y-02 | All new button pairs assert 4.5:1 minimum | Gated (first test green) |
| COMP-08 | refute 10 off-palette utilities + hex | RED — violations remain pre-remediation |
| MOTION-02 | refute transition-all + assert duration-[--motion-fast] | RED |
| COMP-06 | assert po-focus | RED |
| COMP-07 | refute raw badge color utilities (5 patterns) | RED |
| COMP-05 | refute cursor-pointer | RED |
| COMP-02 | assert disabled:opacity | RED |
| COMP-04 | refute border-amber- | RED |

## Deviations from Plan

None — plan executed exactly as written.

The two new gates (COMP-02 `assert disabled:opacity` and COMP-04 `refute border-amber-`) were explicitly listed in the plan's `must_haves.truths` and added per 45-01-PLAN.md task 2 instructions.

## Test State After Plan 01

- **First test** (`"semantic operator tokens meet contrast minimums"`): GREEN — 1 test, 0 failures. All new button contrast pairs are AA-valid.
- **Second test** (`"operator components use semantic tokens..."`): RED — 1 failure. First failing assertion is `refute content =~ "bg-indigo-600"` because `operator_components.ex.eex` still holds the violation pre-remediation.
- **Full suite:** 2 tests, 1 failure — RED-as-expected. Plans 02 and 03 will turn the second test green.

## Known Stubs

None. This plan adds only test assertions — no component changes, no data stubs.

## Threat Flags

None. This plan edits a test file only. No runtime boundary, no user input, no data flow. Forbidden hex/utility strings appear only inside `refute content =~` guards.

## Self-Check: PASSED

- [x] `test/parapet/operator_ui_contrast_test.exs` exists and contains all new assertions
- [x] Commit `1660b1b` exists (Task 1)
- [x] Commit `5e84ecb` exists (Task 2)
- [x] First test passes (green)
- [x] Second test fails for expected reason (RED — `bg-indigo-600` refute failure, not a syntax/compile error)
