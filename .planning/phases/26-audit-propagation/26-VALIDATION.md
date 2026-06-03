---
phase: 26
slug: audit-propagation
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
validated: 2026-05-28
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `26-RESEARCH.md` § Validation Architecture (HIGH confidence — all test touch-points read line-by-line).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs test/parapet/evidence/retrospective_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | quick ~5s · full suite ~30s |

---

## Sampling Rate

- **After every task commit:** Run the quick run command above
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds (full suite)

---

## Per-Task Verification Map

> Task IDs are assigned at plan time. Rows below map each phase requirement (+ success criterion #4) to its observable signal and automated command, all extending existing test modules (no new files — see Wave 0).

| Req | Behavior (observable signal) | Test Type | Automated Command | Status |
|-----|------------------------------|-----------|-------------------|--------|
| AUD-01 | `{:ok}` Confirm → `TimelineEntry.type == "recovery_confirmed"`, payload carries `actor`, `capability`, `target_refs`, `outcome.status == "succeeded"` | unit | `mix test test/parapet/operator_test.exs` (`:594-600`) | ✅ green |
| AUD-02 | `{:ok}` Confirm → `ToolAudit` row: `success: true`, `output` map set, `input` carries `action_name`/`target_refs`/`actor` | unit | `mix test test/parapet/operator_test.exs` (`:603-608`) | ✅ green |
| AUD-02 | Cross-surface: `payload.actor` recorded in `ToolAudit.input` for operator AND automation paths | unit + integration | `mix test test/parapet/operator_test.exs test/parapet/automation/executor_concurrency_test.exs` (`:144`) | ✅ green |
| AUD-03 | `execute/2` → `{:error, reason}` writes `TimelineEntry.type == "recovery_failed"` + `ToolAudit.success == false`; `{:error, reason}` still returned | unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` (CR-02 `:365-378`) | ✅ green |
| AUD-03 | `execute/2` raising (rescued → `{:capability_raised, msg}`) writes a `recovery_failed` entry | unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` (CR-03 `:437-453`) | ✅ green |
| AUD-03 (neg) | Short-circuit arms (`preview_expired`/`target_refs_drift`/`incident_resolved`) write NO TimelineEntry, NO ToolAudit | unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` (`:225-231`, preview_expired arm) | ✅ green |
| AUD-03 (neg) | Conflict arm (`{:conflicted, _}`) writes NO TimelineEntry | integration | `mix test test/parapet/operator/confirm_concurrency_test.exs` (`:195-207`, recovery-entry count == 1) | ✅ green |
| SC-4 | `Retrospective.generate_markdown/1` renders `recovery_confirmed` with human-readable payload (not raw `inspect`) | unit | `mix test test/parapet/evidence/retrospective_test.exs` (`:94,104`) | ✅ green |
| SC-4 | Same renders `recovery_failed` with distinct "Recovery failed: …" wording | unit | `mix test test/parapet/evidence/retrospective_test.exs` (`:97`) | ✅ green |
| SC-4 | Recovery entries appear inline in chronological order (no sidebar/separate section) | unit | `mix test test/parapet/evidence/retrospective_test.exs` (`:108-110`) | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky — all rows ✅ green as of 2026-05-28 audit.*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No new test files; every assertion extends an existing module (`operator_test.exs`, `operator/preview_lifecycle_test.exs`, `evidence/retrospective_test.exs`, plus the cross-surface/conflict integration coverage in `automation/executor_concurrency_test.exs` and `operator/confirm_concurrency_test.exs` added during the 2026-05-28 audit).

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing infra)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-28 — all 10 requirement rows have green automated verification.

---

## Validation Audit 2026-05-28

Initial audit found 8/10 rows COVERED and 2 PARTIAL (test existed but did not directly assert the row's observable signal). Both PARTIALs were filled with additive, test-only assertions (no implementation changes):

- **AUD-02 cross-surface (automation path):** the automation concurrency test asserted `actor` only in the TimelineEntry payload. Added `assert audit.input["actor"] == "system:automation:executor"` (`executor_concurrency_test.exs:144`) to pin the `ToolAudit.input` half of the cross-surface guarantee.
- **AUD-03 negative (conflict arm):** the conflict race test proved the loser never executes but did not directly assert zero recovery writes. Added a DB-count assertion (`confirm_concurrency_test.exs:195-207`) requiring exactly one recovery TimelineEntry (the winner's `recovery_confirmed`), proving the `{:conflicted, _}` arm is silent.

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |

Verification: `mix test test/parapet/operator/confirm_concurrency_test.exs test/parapet/automation/executor_concurrency_test.exs` → 2 tests, 0 failures; targeted suite → 26 tests, 0 failures; `mix compile --warnings-as-errors` clean.
