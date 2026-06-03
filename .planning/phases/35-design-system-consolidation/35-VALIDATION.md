---
phase: 35
slug: design-system-consolidation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
---

# Phase 35 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/parapet/operator_ui_integration_test.exs` |
| **Full suite command** | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` |
| **Estimated runtime** | ~60 seconds |

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/operator_ui_integration_test.exs`
- **After every plan wave:** Run `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs`
- **Before `$gsd-verify-work`:** Full targeted suite plus `mix format --check-formatted` must be green
- **Max feedback latency:** 60 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | UI-DS-01/UI-DS-02 | T-35-01 | Generated UI stays host-owned and dependency-neutral | source-contract | `mix test test/parapet/operator_ui_integration_test.exs` | yes | pending |
| 35-01-02 | 01 | 1 | UI-DS-03/UI-DS-05 | T-35-02 | Mutating controls show audit/risk copy before execution | source-contract | `mix test test/parapet/operator_ui_integration_test.exs` | yes | pending |
| 35-01-03 | 01 | 1 | UI-DS-04 | T-35-03 | Motion remains restrained and no `transition-all` is introduced | source-contract | `mix test test/parapet/operator_ui_integration_test.exs` | yes | pending |
| 35-01-04 | 01 | 1 | UI-DS-01/UI-DS-02/UI-DS-05 | T-35-04 | Demo generated-surface mirror remains aligned | smoke/source-contract | `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-03
