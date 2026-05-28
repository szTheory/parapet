---
status: partial
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
source: [25-VERIFICATION.md]
started: 2026-05-28T02:45:00Z
updated: 2026-05-28T02:45:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Open-incident happy path (Preview → Confirm without acknowledging)
expected: Preview panel shows Action name + Target Kind + Affected Count; Confirm flashes "Mitigation confirmed and executed" and the capability executes. Code + unit/concurrency tests prove `{:ok, recovery_confirmed}` on an open incident; visual render needs human eyes.
result: [pending]

### 2. Acknowledge-then-Confirm path (DECISION POINT)
expected: With current code, after Acknowledge the incident is "investigating", so Confirm returns `{:short_circuited, :incident_resolved}` with the flash "Incident already resolved — no action needed" (mislabeled). The code does NOT force Acknowledge-before-Confirm. Confirm whether your intended operator workflow permits Acknowledge-before-Confirm. If yes → WR-CR01 is a happy-path break; gate/mapping must be fixed before shipping. If operators Confirm directly on open incidents → latent UX wart, not a blocker.
result: [pending]

### 3. Conflict-flash copy on single-node self-conflict
expected: Flash reads "Another node is executing this recovery — refresh to see the outcome" (verbatim ROADMAP criterion #2). On a single-node self-conflict this copy is misleading (WR-WR05). Verify the copy is acceptable or schedule the WR-WR05 rewording.
result: [pending]

### 4. Preview-expired + re-Preview affordance
expected: Flash reads "Preview expired — please re-Preview before confirming" and the Preview button reappears on the runbook card (active preview clears via load_detail re-derive). CONTEXT D-11 mentioned a dedicated "Re-Preview button"; implementation reuses the existing Preview button (RESEARCH A7) — verify the affordance is discoverable.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
