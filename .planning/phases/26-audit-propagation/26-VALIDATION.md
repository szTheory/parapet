---
phase: 26
slug: audit-propagation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-28
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

| Req | Behavior (observable signal) | Test Type | Automated Command | File Exists |
|-----|------------------------------|-----------|-------------------|-------------|
| AUD-01 | `{:ok}` Confirm → `TimelineEntry.type == "recovery_confirmed"`, payload carries `actor`, `capability`, `target_refs`, `outcome.status == "succeeded"` | unit | `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs` | ✅ extend |
| AUD-02 | `{:ok}` Confirm → `ToolAudit` row: `success: true`, `output` map set, `input` carries `action_name`/`target_refs`/`actor` | unit | `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs` | ✅ extend |
| AUD-02 | Cross-surface: `payload.actor` recorded in `ToolAudit.input` for operator AND automation paths | unit | `mix test test/parapet/operator_test.exs` | ✅ extend |
| AUD-03 | `execute/2` → `{:error, reason}` writes `TimelineEntry.type == "recovery_failed"` + `ToolAudit.success == false`; `{:error, reason}` still returned | unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` | ✅ extend CR-02 |
| AUD-03 | `execute/2` raising (rescued → `{:capability_raised, msg}`) writes a `recovery_failed` entry | unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` | ✅ extend CR-03 |
| AUD-03 (neg) | Short-circuit arms (`preview_expired`/`target_refs_drift`/`incident_resolved`) write NO TimelineEntry, NO ToolAudit | unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` | ✅ add neg assertion |
| AUD-03 (neg) | Conflict arm (`{:conflicted, _}`) writes NO TimelineEntry | unit | `mix test test/parapet/operator_test.exs` | ✅ extend |
| SC-4 | `Retrospective.generate_markdown/1` renders `recovery_confirmed` with human-readable payload (not raw `inspect`) | unit | `mix test test/parapet/evidence/retrospective_test.exs` | ✅ extend |
| SC-4 | Same renders `recovery_failed` with distinct "Recovery failed: …" wording | unit | `mix test test/parapet/evidence/retrospective_test.exs` | ✅ extend |
| SC-4 | Recovery entries appear inline in chronological order (no sidebar/separate section) | unit | `mix test test/parapet/evidence/retrospective_test.exs` | ✅ extend |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky — all rows ⬜ pending until execution.*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No new test files; every assertion extends an existing module (`operator_test.exs`, `operator/preview_lifecycle_test.exs`, `evidence/retrospective_test.exs`).

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — existing infra)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
