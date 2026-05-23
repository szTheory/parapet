---
phase: 3
slug: operator-ui-performance
status: complete
nyquist_compliant: true
wave_0_complete: true
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
| **Quick run command** | `mix test test/parapet/operator/queue_pagination_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Canonical Verification Artifact

- `.planning/v0.9-phases/3/VERIFICATION.md` is now the closure-grade proof artifact for this phase.
- This validation contract remains the sampling map, but proof closure for `SCALE-01.c` and `AC-03` is recorded in `VERIFICATION.md` with fresh rerun results from 2026-05-21.
- The named `generated resolve-flow proof lane` now guards the queue-side `"Resolve"` seam in two layers: runtime proof covers active-to-resolved lifecycle behavior, while source-contract proof guards `Parapet.Operator.resolve_incident/2`.

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/operator/queue_pagination_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green and the advisory perf lane must have a captured result
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SCALE-01.c | T-03-01 / T-03-02 | Queue params are bounded, active-only by default, and deterministic under ties | unit/integration | `mix test test/parapet/operator/queue_pagination_test.exs` | ✅ | ✅ green |
| 03-01-02 | 01 | 1 | SCALE-01.c | T-03-03 | Generated migrations and fresh-install schema ship active-queue and resolved-history incident indexes aligned to `updated_at`/`id` browsing | generator integration | Implementation anchored in `.planning/v0.9-phases/3/03-01-SUMMARY.md` and validated by the bounded queue proof in `.planning/v0.9-phases/3/VERIFICATION.md` | ✅ | ✅ green |
| 03-02-01 | 02 | 2 | SCALE-01.c | T-03-04 / T-03-05 / T-03-06 | Generated LiveView loads only one page, validates params, streams bounded rows without silent reordering, and keeps the `generated resolve-flow proof lane` honest by proving queue-side `"Resolve"` moves an incident from the active queue into resolved history through `Parapet.Operator.resolve_incident/2` | generator integration | `mix test test/parapet/generated_operator_live_paging_test.exs` and `mix test test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | ✅ | ✅ green |
| 03-03-01 | 03 | 3 | AC-03 | T-03-07 / T-03-08 / T-03-09 | Perf proof emits low-cardinality telemetry and captures a reproducible 50k+ benchmark lane | advisory perf | `mix run bench/operator_ui_perf.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `test/parapet/operator/queue_pagination_test.exs` — covers active-only scope, deterministic `updated_at`/`id` keyset boundaries, and invalid cursor fallback
- [x] Generator/index proof landed during Phase 3 Plan 01 and remains captured in `.planning/v0.9-phases/3/03-01-SUMMARY.md`
- [x] `test/parapet/operator_ui_integration_test.exs` — anchors the source-contract half of the `generated resolve-flow proof lane` by asserting the generated UI no longer uses mount-time full-queue loading, does use `handle_params/3` plus bounded queue affordances, and keeps queue resolve on `Parapet.Operator.resolve_incident/2`
- [x] `test/parapet/generated_operator_live_paging_test.exs` — anchors the runtime half of the `generated resolve-flow proof lane` by proving bounded current-page rendering, URL-driven cursor navigation, and the queue resolve lifecycle from active queue to resolved history
- [x] `bench/operator_ui_perf.exs` — advisory 50k+ queue fetch + first-render benchmark harness, re-run on 2026-05-21

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Background refresh affordance does not silently reorder the visible queue while detail/counters stay fresh | SCALE-01 | Operator-paced queue semantics are easier to judge from rendered behavior than from isolated unit assertions | Generate the UI, visit the operator queue, create or mutate incidents in the background, confirm the queue shows an explicit refresh affordance instead of reordering rows in place |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or closure evidence in `VERIFICATION.md`
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [x] Feedback latency < 30s for quick commands
- [x] `nyquist_compliant: true` set in frontmatter before execution closure

**Approval:** complete
