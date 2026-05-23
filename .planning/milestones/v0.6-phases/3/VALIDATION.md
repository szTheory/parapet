# Validation for Phase 3: Threadline Compliance Sync

## Goals
Guarantee that all Parapet operator actions satisfy strict compliance requirements by mirroring to Threadline. Ensure the core Parapet framework correctly implements an optional dependency pattern without compile-time or runtime failures if Threadline is omitted.

## Requirements Validated
- **THR-01**: System Parapet.Ecto.ToolAudit can be configured to broadcast audit events to Threadline. System allows operators to defer the storage of audit logs entirely to Threadline in compliance-heavy environments to maintain a single source of truth for administrative actions.

## Validation Protocol

### 1. Configuration Check (`audit_mode: :dual_write`)
- **Action**: Set `Application.put_env(:parapet, :audit_mode, :dual_write)` in tests or runtime. Call `Parapet.Evidence.run_operator_command/1`.
- **Expected Outcome**:
  - A `Parapet.Spine.ToolAudit` record is successfully inserted into the database.
  - A telemetry event `[:parapet, :audit, :created]` is broadcasted via `:telemetry.execute/3`.

### 2. Configuration Check (`audit_mode: :threadline_deferred`)
- **Action**: Set `Application.put_env(:parapet, :audit_mode, :threadline_deferred)`. Call `Parapet.Evidence.run_operator_command/1`.
- **Expected Outcome**:
  - The Ecto transaction succeeds and returns a valid map.
  - **Zero** `ToolAudit` records are inserted into the database.
  - A telemetry event `[:parapet, :audit, :created]` is successfully broadcasted via `:telemetry.execute/3`.

### 3. Decoupling and Telemetry Handling
- **Action**: Trigger `[:parapet, :audit, :created]` telemetry events directly. 
- **Expected Outcome**:
  - `Parapet.Integrations.Threadline.handle_event/4` receives the event.
  - If `Threadline` is loaded in the host app, it maps the payload to the expected shape and calls the Threadline API.
  - If `Threadline` is absent, the handler returns `:ok` without crashing, relying on `Code.ensure_loaded?(Threadline)`.
  - Any exceptions during Threadline integration are rescued and logged, avoiding cascading crashes in the telemetry pipeline.

### 4. Optional Dependency Verification (Compile-Out)
- **Action**: Run `mix compile --warnings-as-errors` in a standard environment where `Threadline` is not defined as a mix dependency.
- **Expected Outcome**: Clean compilation. No undefined module warnings for `Threadline`.

## Automated Validation Suite
All of the above behaviors must be strictly tested via `mix test`.
- Command: `mix test test/parapet/integrations/threadline_test.exs test/parapet/evidence_test.exs`
- Pass criteria: 100% test coverage and 0 failures.