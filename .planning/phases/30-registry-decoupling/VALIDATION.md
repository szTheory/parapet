---
phase: 30
slug: registry-decoupling
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
---

# Phase 30: Registry Decoupling - Validation Plan

## Goal
Validate that `Parapet.SLO` and `Parapet.Capabilities` successfully isolate their state during concurrent test execution via the ETS checkout pattern, allowing `mix test` to run reliably with `async: true` enabled.

## Test Matrix

| Component | Test Type | Target File |
|-----------|-----------|-------------|
| `Parapet.SLO.Registry` | Integration | `test/parapet/slo_test.exs` |
| `Parapet.Capabilities` | Integration | `test/parapet/capabilities_test.exs` |
| `parapet.doctor` mix task | Unit | `test/mix/tasks/parapet.doctor_test.exs` |
| Generators / Config | Unit | `test/parapet/slo/generator_test.exs`, `test/mix/tasks/parapet.gen.prometheus_test.exs` |

## Validation Steps

### 1. Test Isolation & Flake-Free Execution
Run the test suite to ensure no state pollution occurs between processes:
```bash
mix test test/parapet/slo_test.exs test/parapet/capabilities_test.exs test/mix/tasks/parapet.doctor_test.exs
mix test
```
**Expected Outcome:** All tests pass completely green without any flakes on subsequent runs.

### 2. Async Flag Validation
Ensure that `async: true` is properly utilized in the previously blocked test files.
```bash
grep -E "async: true" test/parapet/slo_test.exs test/parapet/capabilities_test.exs test/mix/tasks/parapet.doctor_test.exs
```
**Expected Outcome:** Output confirms the modules use `use ExUnit.Case, async: true`.

### 3. Registry Cleanup / Memory Leak Prevention
Verify `Process.monitor` is used to clean up ETS checkouts when tests finish.
```bash
grep "Process.monitor" lib/parapet/slo/registry.ex lib/parapet/capabilities.ex
```
**Expected Outcome:** Output confirms `Process.monitor(pid)` exists in both modules.

## Phase Acceptance Criteria
- [ ] No `Application.put_env(:parapet, :providers, ...)` overrides are present in the test suites.
- [ ] `Parapet.Capabilities` has been migrated off `Agent` and uses the ETS checkout pattern.
- [ ] `mix test` completes entirely green with `async: true` for the targeted tests.
