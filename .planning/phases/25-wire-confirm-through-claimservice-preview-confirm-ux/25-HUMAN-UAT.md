---
status: complete
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
source: [25-VERIFICATION.md]
started: 2026-05-28T02:45:00Z
updated: 2026-06-03T19:00:00Z
---

## Current Test

[closed at milestone pre-flight — all 4 items remain documented as deferred LiveView visual/real-time render confirmations; the CR-01 product decision is RESOLVED and fixed]

## Tests

### 1. Open-incident happy path (Preview → Confirm without acknowledging)
expected: Preview panel shows Action name + Target Kind + Affected Count; Confirm flashes "Mitigation confirmed and executed" and the capability executes. Code + unit/concurrency tests prove `{:ok, recovery_confirmed}` on an open incident; visual render needs human eyes.
result: deferred to post-close visual UAT

### 2. Acknowledge-then-Confirm path (CR-01 RESOLVED — now a visual confirmation)
expected: Decision resolved YES (ack-then-confirm is a valid workflow) and the code is fixed (commit 65e5ee5): the claim gate now accepts "investigating", so after Acknowledge → Preview → Confirm the operator sees the success flash and the capability executes — no more spurious "Incident already resolved". Covered by passing tests; confirm the success flash renders for the acknowledged path.
result: deferred to post-close visual UAT

### 3. Conflict-flash copy (multi-node) — WR-04 self-conflict path now closed
expected: WR-04 is FIXED (commit b39b402): after a successful Confirm the step is marked executed and the Confirm affordance clears, so the double-click self-conflict that made the multi-node copy misleading on a single node is no longer reachable. The verbatim "Another node is executing this recovery — refresh to see the outcome" string remains for genuine multi-node contention (ROADMAP criterion #2). Confirm the copy reads acceptably in the real multi-node case.
result: deferred to post-close visual UAT

### 4. Preview-expired + re-Preview affordance
expected: Flash reads "Preview expired — please re-Preview before confirming" and the Preview button reappears on the runbook card (active preview clears via load_detail re-derive). CONTEXT D-11 mentioned a dedicated "Re-Preview button"; implementation reuses the existing Preview button (RESEARCH A7) — verify the affordance is discoverable.
result: deferred to post-close visual UAT

## Summary

total: 4
passed: 0
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

No code or contract gaps. The four remaining checks are visual/real-time demo confirmations and were acknowledged as deferred during v1.2 milestone closeout pre-flight on 2026-06-03.
