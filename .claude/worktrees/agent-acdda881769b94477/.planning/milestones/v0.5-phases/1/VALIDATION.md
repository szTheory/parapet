# Phase 1: Synthetic Probes - Validation Plan

**Goal:** Operators can define periodic active checks to maintain SLO signal quality even when organic user traffic is too low for stable math.

This document serves as the Nyquist compliance checklist to ensure all implementation requirements from Phase 1 are verifiably completed and tested.

## 1. Parapet.Probe Macro and Telemetry Emission

* **Requirement:** Developers can use `Parapet.Probe`, implement `run/0`, and it implicitly wraps the call to emit telemetry via `execute/0`.
* **Verification Command:** `mix test test/parapet/probe_test.exs`
* **Explicit Checks:**
  - [ ] `Parapet.Probe` macro successfully injects `execute/0`.
  - [ ] Executing the probe emits a `:telemetry.span` for event `[:parapet, :probe, :run]`.
  - [ ] Output metadata contains the `probe` module name and `status` (`"success"` or `"error"`).

## 2. NativeScheduler Adapter Functionality

* **Requirement:** A standalone, in-memory `GenServer` timer can successfully schedule probes for setups without Oban.
* **Verification Command:** `mix test test/parapet/probe/native_scheduler_test.exs`
* **Explicit Checks:**
  - [ ] `Parapet.Probe.NativeScheduler` starts and accepts a schedule of modules and intervals.
  - [ ] The GenServer correctly dispatches calls to the underlying probe's `execute/0` function at the specified intervals.

## 3. ObanScheduler Adapter Functionality

* **Requirement:** A distributed scheduler runs probes using Oban cron functionalities and strictly disables retries to prevent muddying SLO metrics.
* **Verification Command:** `mix test test/parapet/probe/oban_scheduler_test.exs`
* **Explicit Checks:**
  - [ ] `Parapet.Probe.ObanScheduler` defines an Oban worker with `max_attempts: 1` hardcoded.
  - [ ] The worker accurately extracts the probe module from job arguments and delegates to its `execute/0` function.
  - [ ] Validation is in place to ensure the worker only invokes valid implementations of `Parapet.Probe`.

## 4. Parapet.Metrics.Probe Setup and Safe Labels

* **Requirement:** The probe metrics handler correctly listens for probe executions and emits safe Prometheus metrics without risking high cardinality memory exhaustion.
* **Verification Command:** `mix test test/parapet/metrics/probe_test.exs`
* **Explicit Checks:**
  - [ ] Handlers are successfully attached to `[:parapet, :probe, :run, :stop]` and `[:parapet, :probe, :run, :exception]` during `setup/0`.
  - [ ] Prometheus distributions and counters are correctly generated in `metrics/0`.
  - [ ] `LabelPolicy.assert_safe!([:probe, :status])` is strictly enforced to block unsafe/high-cardinality labels (mitigates Threat ID T-1-01).

## Integration and End-to-End Checks

- [ ] Run `mix test` to confirm all probe and scheduler tests pass.
- [ ] Run `mix compile` to ensure the installer task (`parapet.install.ex`) cleanly references the new `Parapet.Metrics.Probe.setup()` without errors.
- [ ] Confirm `README.md` and `docs/telemetry.md` expose the scheduler and probe telemetry concepts clearly.