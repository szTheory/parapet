---
phase: 36
slug: demo-state-coverage-browser-verification
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
---

# Phase 36 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, demo Phoenix app smoke tests, local Chromium screenshot capture |
| **Config file** | `mix.exs`, `examples/demo_app/mix.exs` |
| **Quick run command** | `mix test test/parapet/operator_ui_demo_contract_test.exs` |
| **Full suite command** | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_demo_contract_test.exs && cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` |
| **Browser proof command** | `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` |
| **Estimated runtime** | ~180 seconds plus local server startup |

## Sampling Rate

- **After seed/route changes:** Run the demo contract test.
- **After browser script changes:** Run demo reset, assets build, demo server, and screenshot capture.
- **Before milestone verification:** Run generated UI tests, demo smoke tests, demo reset, assets build, screenshot capture, and touched-file formatting.
- **Max feedback latency:** 300 seconds for targeted browser proof.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | UI-DEMO-01 | T-36-01 | Demo seeds remain deterministic and host-owned | source-contract | `mix test test/parapet/operator_ui_demo_contract_test.exs` | yes | green |
| 36-01-02 | 01 | 1 | UI-DEMO-02, UI-VERIFY-01 | T-36-02 | Demo routes mirror generated route guidance without changing auth ownership | source + smoke | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_demo_contract_test.exs && cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` | yes | green |
| 36-01-03 | 01 | 1 | UI-VERIFY-02 | T-36-03 | Browser proof captures response, actions, history, and detail routes on desktop and mobile | browser | `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` | yes | green |

## Wave 0 Requirements

Existing Phase 34 and Phase 35 generated UI source-contract tests cover route guidance, compatibility detail behavior, component helper consistency, action affordances, focus states, and restrained motion before Phase 36 browser proof runs.

## Manual-Only Verifications

None. Phase 36 uses automated source-contract, smoke, and browser screenshot evidence.

## Validation Sign-Off

- [x] All tasks have automated verify or explicit prerequisite coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all prerequisite references from Phases 34 and 35
- [x] No watch-mode flags
- [x] Feedback latency target documented for browser proof
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-03
