# Phase 1 - Plan 2 Summary (Synthetic Probe Schedulers)

## Objective Completed
Implemented pluggable schedulers for executing probes: `NativeScheduler` for standalone memory-based timers and `ObanScheduler` for distributed clustered setups without retries.

## Tasks Completed
1. **Parapet.Probe.NativeScheduler:** Created as a GenServer to dispatch probe execution continuously based on a simple configuration `[{MyProbe, 60_000}]`.
2. **Parapet.Probe.ObanScheduler:** Created as an Oban worker configured with `max_attempts: 1`. It dynamically invokes the probe using `apply(module, :execute, [])`.

## Security & Verification
- `max_attempts: 1` explicitly asserted and verified in tests.
- Dynamically invoked probe module is validated via `Code.ensure_loaded?` and `function_exported?`.
- Automated test coverage provided for both native timer scheduling and Oban worker logic.