---
phase: 38
slug: scoped-ui-routes
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 38 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_demo_contract_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | Quick lane under 60 seconds; full suite project-dependent |

## Sampling Rate

- **After every task commit:** Run the quick route-focused command above.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 60 seconds for scoped route regressions in the quick lane.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 38-01-01 | 01 | 1 | UIROUTE-01 | T-38-01 | Generated links, patches, redirects, and route helpers keep local navigation under the active host scope. | unit/render contract | `mix test test/parapet/generated_operator_live_paging_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | yes | green |
| 38-01-02 | 01 | 1 | UIROUTE-02 | T-38-02 | Generated templates and checked-in demo copies render matching default and scoped route behavior. | contract | `mix test test/parapet/operator_ui_demo_contract_test.exs test/parapet/operator_ui_integration_test.exs` | yes | green |
| 38-01-03 | 01 | 1 | UIROUTE-03 | T-38-03 | Scoped route support does not add auth/router ownership, stable public APIs, or direct Phoenix/LiveView core dependencies. | regression/static | `mix test test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_integration_test.exs` | yes | green |

## Wave 0 Requirements

- [x] Add scoped route assertions to `test/parapet/generated_operator_live_paging_test.exs` for `/ops/parapet`, including history detail links and queue patches.
- [x] Add generator output assertions in `test/mix/tasks/parapet.gen.ui_test.exs` for the generated base-path seam and absence of raw local `/parapet` literals outside helper/default definitions.
- [x] Add demo-copy scoped assertions in `test/parapet/operator_ui_demo_contract_test.exs` or `test/parapet/operator_ui_integration_test.exs`.

## Manual-Only Verifications

All phase behaviors have automated verification. A browser smoke test against the demo app is optional if planning chooses to add a runnable `/ops/parapet` demo route, but it is not required by the current validation architecture.

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target below 60 seconds for scoped route regressions.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-04
