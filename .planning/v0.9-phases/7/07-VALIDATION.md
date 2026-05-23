---
phase: 7
slug: close-operator-ui-performance-proof
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
---

# Phase 7 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix benchmark lane |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/operator/queue_pagination_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` |
| **Proof lane** | `mix run bench/operator_ui_perf.exs` |
| **Estimated runtime** | ~30-60 seconds plus benchmark time |

## Sampling Rate

- **After each task commit in 07-01:** rerun the targeted Phase 3 queue proof tests affected by the edit, including the generated queue resolve regression lane.
- **Before closing 07-01:** rerun the full targeted proof suite plus `mix run bench/operator_ui_perf.exs`.
- **Before closing 07-02:** verify the reconciled docs point directly at the new verification artifact and only the intended traceability rows changed.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 07-01-01 | 01 | 1 | `SCALE-01.c` | unit/integration | `mix test test/parapet/operator/queue_pagination_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | planned |
| 07-01-02 | 01 | 1 | `AC-03` | advisory perf | `mix run bench/operator_ui_perf.exs` | planned |
| 07-02-01 | 02 | 2 | `SCALE-01.c`, `AC-03` | doc reconciliation | `rg -n "VERIFICATION.md|generated_operator_live_paging_test|resolve|Phase 7|SCALE-01.c|AC-03" .planning/v0.9-phases/3/VERIFICATION.md .planning/v0.9-phases/3/03-VALIDATION.md .planning/REQUIREMENTS.md .planning/ROADMAP.md` | planned |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Benchmark wording stays honest and does not imply a universal latency guarantee | `AC-03` | This is a documentation and proof-honesty judgment, not a pure unit-test concern | Review `.planning/v0.9-phases/3/VERIFICATION.md` and `docs/operator-ui.md` together; confirm they describe the lane as reproducible and advisory rather than a hard SLA, and that queue-side resolve proof remains in the targeted runtime/source-contract lanes |

## Validation Sign-Off

- [x] All tasks have an automated verification path
- [x] No watch-mode flags
- [x] Proof surfaces are rerunnable in this repo
- [x] Benchmark lane is explicitly advisory
- [x] Reconciliation scope is narrow and directly traceable

**Approval:** ready for execution
