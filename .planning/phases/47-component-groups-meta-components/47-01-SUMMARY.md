---
phase: 47-component-groups-meta-components
plan: "01"
subsystem: test
tags: [tdd, red-scaffold, a11y, motion, brand-voice, test-gate]
requires: []
provides: [47-01-red-scaffold]
affects: [operator_ui_contrast_test]
tech_stack:
  added: []
  patterns: [ExUnit string assert/refute, ~S sigil for embedded quotes, additive test loop extension]
key_files:
  modified:
    - test/parapet/operator_ui_contrast_test.exs
decisions:
  - "All Phase-47 assertions added additively to existing operator_ui_contrast_test.exs — no new test files (D-15)"
  - "~S sigil used for assertion strings containing embedded double-quotes and square-bracket selectors"
  - "class=\"fixed inset-0 guard scoped to full-screen scrim pattern only — preview_panel's fixed inset-x-0 bottom-0 is a distinct string (Pitfall 1)"
  - "Positive-assert approach for GROUP-02 brand-voice (assert new labels, refute old); Observability old label not refuted per Pitfall 3"
  - "Both Task 1 (@component_paths) and Task 2 (@detail_template_paths) committed atomically in one commit (single-file sequential edits)"
metrics:
  duration: "1m"
  completed: "2026-06-26"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
status: complete
---

# Phase 47 Plan 01: Wave-0 RED Test Scaffold Summary

**One-liner:** Extended `operator_ui_contrast_test.exs` with 19 new Phase-47 assertions across both test loops — all fail RED confirming the binding contract before 47-02 ships markup.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add Phase-47 assertions to @component_paths loop (RED) | 9862032 | test/parapet/operator_ui_contrast_test.exs |
| 2 | Add D-02 scroll-padding assertion to @detail_template_paths loop (RED) | 9862032 | test/parapet/operator_ui_contrast_test.exs |

## What Was Built

Extended the existing `test/parapet/operator_ui_contrast_test.exs` with two sets of additive assertions:

### Task 1 — @component_paths loop (lines 192–228 added)

Covers all Phase-47 automated requirements:

- **GROUP-01 (D-06):** `assert content =~ "break-words"` — cockpit `<h2>` overflow hardening
- **GROUP-02 (D-11):** Four formula-label asserts ("What users are seeing", "Evidence on record", "Where to inspect", "Safe next step") + two updated-fallback asserts + two old-label refutes ("Impact Summary", "Top Facts")
- **GROUP-03/05/06 + A11Y-05 N/A guards (D-16):** `refute role="dialog"`, `refute aria-modal`, `refute ~S|class="fixed inset-0|` (scrim guard), `assert "md:relative md:inset-auto"` (Disclosure shape)
- **A11Y-05 landmark (D-03):** `assert ~S|role="region"|`, `assert ~S|aria-label="Recovery Preview"|`
- **GROUP-04 (D-07/D-08/D-09):** `assert "action_item_risk"`, `assert "Resolved · audited"`, `assert ~S|[aria-disabled="true"]|`
- **MOTION-03 (D-13):** `assert "@keyframes po-preview-reveal"`, `assert "animation: po-preview-reveal var(--motion-base) var(--motion-ease)"`

### Task 2 — @detail_template_paths loop (1 line added)

- **D-02 / A11Y-05 / WCAG 2.4.11 (C43):** `assert content =~ "scroll-pb-72"` with inline decision citation

## RED State Confirmed

```
mix test test/parapet/operator_ui_contrast_test.exs
4 tests, 2 failures — RED-CONFIRMED
```

- Failure 1: `assert content =~ "What users are seeing"` — labels not yet renamed in templates (ships in 47-02)
- Failure 2: `assert content =~ "scroll-pb-72"` — `<main>` class not yet updated in `operator_detail_live` (ships in 47-02)

The two already-passing tests continue to pass (contrast ratios + live template tokens). Compilation is clean — zero syntax errors.

## Deviations from Plan

None — plan executed exactly as written.

Both tasks touch the same file (`operator_ui_contrast_test.exs`); committed atomically in one commit (`9862032`) covering both task sets. This is intentional: sequential edits to a single file cannot be split without interactive staging, and the commit message documents both tasks clearly.

## Assertions NOT Duplicated (per plan prohibitions)

Per the plan's `<done>` criteria, the following pre-existing assertions were verified present and NOT duplicated:
- Line 107: `assert content =~ ~S|aria-label="Close Recovery Preview"|` — already present
- Line 143: `refute content =~ "transition-all"` — already present
- Line 124: `assert content =~ "--motion-fast: 0ms"` — already present

## Self-Check: PASSED

- [x] `test/parapet/operator_ui_contrast_test.exs` modified: `git log --oneline -1` → `9862032`
- [x] No new test files created (`git status` shows only `operator_ui_contrast_test.exs`)
- [x] RED confirmed: `mix test` exits 1 with 2 failures
- [x] Compilation clean: no syntax errors
- [x] `~S` sigil used for: `class="fixed inset-0`, `role="region"`, `aria-label="Recovery Preview"`, `[aria-disabled="true"]`
