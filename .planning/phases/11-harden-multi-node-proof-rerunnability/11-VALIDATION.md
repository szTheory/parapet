---
phase: 11
slug: harden-multi-node-proof-rerunnability
status: active
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for multi-node proof-lane honesty, rerunnability, and proof-surface reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/automation/executor_concurrency_test.exs test/parapet/automation/executor_cluster_smoke_test.exs test/mix/tasks/parapet.doctor_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/automation/executor_concurrency_test.exs test/parapet/automation/executor_cluster_smoke_test.exs test/mix/tasks/parapet.doctor_test.exs`
- **After every plan wave:** Run the same targeted Phase 11 suite unless runtime code changed outside the proof lane.
- **Before `$gsd-verify-work`:** Targeted tests and proof-surface assertions must be green.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | `SCALE-02` | T-11-01 | Real-Repo contention still proves one executed effect path, one conflict no-op, and one audit record. | integration | `mix test test/parapet/automation/executor_concurrency_test.exs` | ✅ | ✅ green |
| 11-01-02 | 01 | 1 | `SCALE-02` | T-11-02 | Peer canary either runs successfully across BEAMs or is skipped when unsupported with a truthful reason that says distributed Erlang unavailable. | smoke | `mix test test/parapet/automation/executor_cluster_smoke_test.exs` | ✅ | ✅ green |
| 11-02-01 | 02 | 2 | `SCALE-02` | T-11-05 | Verification and validation artifacts describe the DB-backed contention suite as closure-grade proof and the peer canary as environment-conditional corroboration. | docs | `rg -n "closure-grade proof|contention suite|environment-conditional|skipped when unsupported|distributed Erlang unavailable" .planning/v0.9-phases/5/VERIFICATION.md .planning/v0.9-phases/5/05-VALIDATION.md .planning/v0.9-phases/5/05-02-SUMMARY.md .planning/v0.9-phases/11/VERIFICATION.md` | ✅ | ✅ green |
| 11-02-02 | 02 | 2 | certainty boundary | T-11-06 | Doctor remains advisory and does not become a distributed-correctness proof lane. | unit/integration | `rg -n "doctor remains advisory|advisory only|cannot prove distributed correctness" .planning/v0.9-phases/5/05-VALIDATION.md .planning/phases/11-harden-multi-node-proof-rerunnability/11-VALIDATION.md && mix test test/mix/tasks/parapet.doctor_test.exs` | ✅ | ✅ green |
| 11-03-01 | 03 | 3 | `SCALE-02` | T-11-09 | Active requirement traceability promotes `SCALE-02` to verified only after the corrected proof chain exists. | docs | `rg -n "\\| SCALE-02 \\| Phase 11 \\| Verified \\|" .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 11-03-02 | 03 | 3 | milestone truth | T-11-10 / T-11-11 | The roadmap Phase 11 closure points to the corrected proof artifacts and keeps the historical audit separate from a fresh rerun. | docs | `rg -n "11-01-PLAN\\.md|11-02-PLAN\\.md|11-03-PLAN\\.md|v0\\.9-phases/11/VERIFICATION\\.md|v0\\.9-phases/5/VERIFICATION\\.md|environment-conditional|historical gap artifact|fresh .*audit rerun" .planning/ROADMAP.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `test/parapet/automation/executor_cluster_smoke_test.exs` now has a reusable distribution-readiness preflight that avoids a hard `Node.start/2` match on unsupported environments.
- [x] `.planning/v0.9-phases/5/VERIFICATION.md` now states that the peer lane is conditional corroboration, not an unconditional pass surface.
- [x] `.planning/v0.9-phases/5/05-VALIDATION.md` now aligns the Nyquist map to the same proof hierarchy and explicit skip/pass contract.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Verify the exact skip wording is honest and non-misleading for unsupported environments. | `SCALE-02` | The command outcome is automated, but the proof-surface wording still needs human review. | Read `test/parapet/automation/executor_cluster_smoke_test.exs`, `.planning/v0.9-phases/5/VERIFICATION.md`, and `.planning/v0.9-phases/11/VERIFICATION.md`; confirm they state that the peer-node canary was skipped when distributed Erlang was unavailable instead of implying peer execution ran. |

---

## Validation Sign-Off

- [x] All completed tasks have automated verification paths or explicit doc assertions
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** active
