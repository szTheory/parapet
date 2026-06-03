---
status: complete
mode: shift-left
phase: 04-operator-ui-surfacing
source: [04-VERIFICATION.md, test/mix/tasks/parapet.gen.ui_shift_left_test.exs]
started: 2026-05-19T13:50:51Z
updated: 2026-05-19T14:11:31Z
human_steps_required: 0
automation_deferred: []
---

# Phase 4 UAT

## Current Test

[testing complete]

## Tests

### 1. Escalation Summary Render
expected: The summary panel shows the escalation chain, the countdown copy, and keeps that summary above the canonical timeline.
result: pass
evidence: `test/mix/tasks/parapet.gen.ui_shift_left_test.exs` asserts generated host UI source renders escalation summary content and places summary usage before the canonical timeline.

### 2. Non-Open Escalation Guard
expected: Escalation controls are replaced by the non-open guard copy and no trigger/suppress actions are offered.
result: pass
evidence: `test/mix/tasks/parapet.gen.ui_shift_left_test.exs` asserts generated host UI source gates controls behind `escalation_controls_enabled?/1`, preserves the open-only guard copy, and encodes false for non-open incidents.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.
