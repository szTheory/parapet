---
phase: 3
slug: operator-ui-performance
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-20
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/operator_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/generated_operator_live_paging_test.exs test/mix/tasks/parapet.gen.ui_test.exs -x` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/operator_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/generated_operator_live_paging_test.exs test/mix/tasks/parapet.gen.ui_test.exs -x`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green and the advisory perf lane must have a captured result
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SCALE-01 | T-03-01 / T-03-02 | Queue params are bounded, active-only by default, and deterministic under ties | unit/integration | `mix test test/parapet/operator/queue_pagination_test.exs -x` | ❌ Wave 0 | ⬜ pending |
| 03-01-02 | 01 | 1 | SCALE-01 | T-03-03 | Generated migrations and fresh-install schema ship active-queue and resolved-history incident indexes aligned to `updated_at`/`id` browsing | generator integration | `mix test test/mix/tasks/parapet.gen.archive_indexes_test.exs test/mix/tasks/parapet.gen.spine_test.exs -x` | ⚠ partial | ⬜ pending |
| 03-02-01 | 02 | 2 | SCALE-01 | T-03-04 / T-03-05 / T-03-06 | Generated LiveView loads only one page, validates params, and streams bounded rows without silent reordering | generator integration | `mix test test/parapet/operator_ui_integration_test.exs test/parapet/generated_operator_live_paging_test.exs test/mix/tasks/parapet.gen.ui_test.exs -x` | ❌ Wave 0 | ⬜ pending |
| 03-03-01 | 03 | 3 | SCALE-01 | T-03-07 / T-03-08 / T-03-09 | Perf proof emits low-cardinality telemetry and captures a reproducible 50k+ benchmark lane | advisory perf | `mix run bench/operator_ui_perf.exs` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/parapet/operator/queue_pagination_test.exs` — cover active-only scope, deterministic `updated_at`/`id` keyset boundaries, and invalid cursor fallback
- [ ] Extend `test/mix/tasks/parapet.gen.archive_indexes_test.exs` and `test/mix/tasks/parapet.gen.spine_test.exs` — assert active-queue and resolved-history incident partial indexes using `updated_at`/`id`
- [ ] Extend `test/parapet/operator_ui_integration_test.exs` — assert the generated UI no longer uses mount-time `Repo.all(Parapet.Operator.queue_query())` and does use `handle_params/3` + streams
- [ ] `test/parapet/generated_operator_live_paging_test.exs` — seed deterministic incident fixtures and behaviorally prove bounded current-page rendering plus URL-driven cursor navigation
- [ ] `bench/operator_ui_perf.exs` — advisory 50k+ queue fetch + first-render benchmark harness

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Background refresh affordance does not silently reorder the visible queue while detail/counters stay fresh | SCALE-01 | Operator-paced queue semantics are easier to judge from rendered behavior than from isolated unit assertions | Generate the UI, visit the operator queue, create or mutate incidents in the background, confirm the queue shows an explicit refresh affordance instead of reordering rows in place |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for quick commands
- [ ] `nyquist_compliant: true` set in frontmatter before execution closure

**Approval:** pending
