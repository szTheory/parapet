---
status: partial
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
source: [25-VERIFICATION.md]
started: 2026-05-28T02:45:00Z
updated: 2026-05-28T07:26:00Z
---

## Current Test

[awaiting human testing — all 4 items are LiveView visual/real-time render confirmations; the CR-01 product decision is RESOLVED and fixed]

## Tests

### 1. Open-incident happy path (Preview → Confirm without acknowledging)
expected: Preview panel shows Action name + Target Kind + Affected Count; Confirm flashes "Mitigation confirmed and executed" and the capability executes. Code + unit/concurrency tests prove `{:ok, recovery_confirmed}` on an open incident; visual render needs human eyes.
result: [pending]

### 2. Acknowledge-then-Confirm path (CR-01 RESOLVED — now a visual confirmation)
expected: Decision resolved YES (ack-then-confirm is a valid workflow) and the code is fixed (commit 65e5ee5): the claim gate now accepts "investigating", so after Acknowledge → Preview → Confirm the operator sees the success flash and the capability executes — no more spurious "Incident already resolved". Covered by passing tests; confirm the success flash renders for the acknowledged path.
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
