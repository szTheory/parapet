# Phase 1 - Plan 3 Summary (Wiring & Documentation)

## Objective Completed
Wired up the synthetic probe telemetry in the installer and provided comprehensive documentation for configuring and executing the probes.

## Tasks Completed
1. **Mix Task Installation:** Updated `lib/mix/tasks/parapet.install.ex` to inject `Parapet.Metrics.Probe.setup()` into the generated telemetry `setup/0` block. This guarantees telemetry is initialized at application boot.
2. **Documentation Updated:**
   - Modified `README.md` to document the new Synthetic Probes feature, providing code snippets for creating probes and configuration examples for both `NativeScheduler` and `ObanScheduler`.
   - Updated `docs/telemetry.md` to formally document the `[:parapet, :probe, :run, :stop]` and `[:parapet, :probe, :run, :exception]` telemetry events, detailing their metrics and metadata.

## Security & Verification
- Telemetry events explicitly declare the fields attached to the metadata, satisfying the requirement that labels remain safe (probe name and status) to prevent high cardinality issues.
- `mix compile` ensures the project is syntactically sound.
- All tasks in Phase 1 execution are complete.