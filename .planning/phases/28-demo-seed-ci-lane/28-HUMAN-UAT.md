---
status: partial
phase: 28-demo-seed-ci-lane
source: [28-VERIFICATION.md]
started: 2026-05-28T20:20:00Z
updated: 2026-05-28T20:20:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Browser click-through of Preview → Confirm in the operator LiveView
steps: `cd examples/demo_app && mix setup && mix phx.server`, open `/parapet`, find the "Stalled async executor" open incident, click through Preview then Confirm on the "Retry Item" step.
expected: Preview panel displays count=1 plus target_refs, preconditions, warnings, and summary; the Confirm button executes the capability; the incident's linked ActionItem transitions state from `open` to `resolved`; a `recovery_confirmed` TimelineEntry appears in the incident timeline.
why_human: LiveView rendering of the preview panel (blast-radius indicator, expected diff, operator-actionable error branches) requires visual inspection. The DB mutation and audit trail are already contract-tested by the four `:smoke` scenarios — only the rendered UI requires human eyes.
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
