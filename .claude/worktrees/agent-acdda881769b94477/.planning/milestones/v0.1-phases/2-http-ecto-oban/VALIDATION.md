# Phase 2 Validation

## Pre-Requisites
- Phase 2 code is committed and tests are passing.

## Verification Steps

### 1. HTTP Metrics Validation
- **Action**: Inspect `Parapet.Plug.Metrics` integration and run tests.
- **Expected Outcome**: 
  - Plug extracts route from `conn.private[:phoenix_route]` correctly.
  - Telemetry hooks map status codes correctly into 2xx, 3xx, 4xx, 5xx blocks.
  - Fallback routes with no router match are bucketed gracefully under `"_unknown"`.
- **Status**: [ ]

### 2. Ecto Metrics Validation
- **Action**: Inspect `Parapet.Metrics.Ecto` and run tests.
- **Expected Outcome**:
  - Time is correctly bucketed into distinct distributions (`queue_time_ms` vs `query_time_ms`).
  - Native driver duration converts effectively to milliseconds.
  - `_raw` label fallback functions as expected for source-less statements.
- **Status**: [ ]

### 3. Oban Metrics Validation
- **Action**: Inspect `Parapet.Metrics.Oban` and verify OBAN-02 logic.
- **Expected Outcome**:
  - Telemetry `parapet_oban_jobs_total` metric is successfully defined as a counter.
  - Metric explicitly contains labels `[:worker, :queue, :state]` to supply `rate()` based signatures for Phase 3 alerting.
  - Component fails gracefully and omits compilation if `Oban` is missing from the environment.
- **Status**: [ ]

### 4. Resiliency & Integrity Validation
- **Action**: Ensure all telemetry registers reliably.
- **Expected Outcome**:
  - All calls to `Telemetry.Metrics` register wrapped inside `try/rescue ArgumentError`.
  - Modules use `Parapet.attach/1` instead of bare telemetry.
  - Cardinality check `Parapet.Internal.LabelPolicy.assert_safe!/1` guarantees metrics hold bounded sets.
- **Status**: [ ]