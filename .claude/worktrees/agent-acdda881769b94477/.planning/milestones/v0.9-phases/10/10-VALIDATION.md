---
phase: 10
slug: tighten-archive-retention-semantics
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for archive-retention semantics repair and proof reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with repo-backed test helper |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs -x` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30-60 seconds for targeted checks |

---

## Sampling Rate

- **After every task commit:** Run the targeted archive tests touched by that task.
- **After every plan wave:** Run `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs`
- **Before `$gsd-verify-work`:** Targeted archive tests must be green and proof/doc assertions must match the corrected semantics.
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | `SCALE-01.b` | T-10-01 | Only resolved incidents older than retention are archived and deleted; old `investigating` incidents remain active. | unit/integration | `mix test test/parapet/evidence/archiver_test.exs -x` | ✅ | ⬜ pending |
| 10-01-02 | 01 | 1 | `AC-02` | T-10-01 / T-10-03 | `mix parapet.archive --days 90` preserves CLI behavior while leaving active work untouched. | unit/integration | `mix test test/mix/tasks/parapet.archive_test.exs -x` | ✅ | ⬜ pending |
| 10-01-03 | 01 | 1 | `AC-02` | T-10-01 / T-10-03 | Optional Oban scheduling path shares the corrected retention semantics. | unit/integration | `mix test test/parapet/evidence/archive_worker_test.exs -x` | ✅ | ⬜ pending |
| 10-02-01 | 02 | 2 | `SCALE-01.b`, `AC-02` | T-10-02 | Phase 2 verification and active milestone truth surfaces stop claiming the contradicted non-open semantics. | doc assertion | `rg -n "resolved incidents|investigating|SCALE-01.b|AC-02" .planning/v0.9-phases/2/VERIFICATION.md .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/v0.9-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit infrastructure covers runtime archive behavior.
- [x] Existing targeted test files already exist and need semantic tightening, not new harnesses.
- [x] Existing proof surfaces exist and need reconciliation, not new verification formats.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Verification wording stays truthful and does not overclaim broader archival semantics. | `SCALE-01.b`, `AC-02` | This is a proof-honesty judgment across planning artifacts, not just a unit-test concern. | Review `.planning/v0.9-phases/2/VERIFICATION.md` and `.planning/v0.9-MILESTONE-AUDIT.md` together; confirm the repaired evidence says resolved-only archival and still points to rerunnable test commands. |

---

## Validation Sign-Off

- [x] All tasks have automated verification paths or explicit doc assertions
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned
