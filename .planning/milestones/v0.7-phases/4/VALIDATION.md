# Validation for Phase 4: Async & Delivery Telemetry Contracts

## Goals

Guarantee that Phase 4 establishes a stable, low-cardinality async/delivery telemetry contract for `Mailglass`, `Chimeway`, and `Rindle`, while preserving compile-out behavior and making the public namespace safe for downstream metrics and incident logic.

## Requirements Validated

- **DELV-01**: System distinguishes `attempted`, `provider_accepted`, `delivered`, `failed`, `bounced`, `complained`, and `suppressed` delivery outcomes where supported.
- **TRIAGE-01**: System normalizes async and delivery telemetry into bounded fault-domain metadata such as `provider`, `queue`, `pipeline_stage`, `outcome`, `failure_class`, and coarse delay buckets without leaking high-cardinality identifiers into metrics labels.

## Validation Protocol

### 1. Contract Primitive Validation

- **Action**: Exercise the Phase 4 contract helpers and label policy against supported families and unsupported keys.
- **Expected Outcome**:
  - allowed metadata/tag keys are accepted for each event family
  - disallowed keys are rejected or diverted into `refs`
  - delay buckets, retry states, outcomes, and fault planes stay bounded

### 2. Delivery Adapter Translation Validation

- **Action**: Emit representative `Mailglass` and `Chimeway` upstream telemetry for outbound attempts, provider feedback, webhook ingest, and failure cases.
- **Expected Outcome**:
  - Parapet emits the new `[:parapet, :delivery, ...]` event families
  - acceptance stays distinct from terminal delivery
  - suppression, bounce, complaint, and webhook drift remain distinguishable
  - unsafe identifiers are not exposed as public labels

### 3. Async Adapter Translation Validation

- **Action**: Emit representative `Rindle` upstream telemetry for stage transitions, retryable failure, discard, backlog, and callback delay.
- **Expected Outcome**:
  - Parapet emits the new `[:parapet, :async, ...]` event families
  - `retryable_failed` remains distinct from `discarded`
  - callback or reconciliation delay stays distinct from queue backlog
  - unsafe identifiers are not exposed as public labels

### 4. Compile-Out and Activation Validation

- **Action**: Compile and run the targeted test suite in the standard repo environment.
- **Expected Outcome**:
  - clean compilation with warnings treated as errors
  - adapter activation still flows through explicit `Parapet.attach(adapters: [...])`
  - no new hard dependency coupling is introduced for optional integrations

### 5. Public Contract Documentation Validation

- **Action**: Update and review the public docs and public API proof surfaces.
- **Expected Outcome**:
  - docs describe the new event families and bounded metadata contract
  - any newly public module passes `verify.public_api`
  - the blessed adoption path is explicit and matches the implementation

## Automated Validation Suite

- `mix test test/parapet/internal/label_policy_test.exs test/parapet_test.exs`
- `mix test test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs`
- `mix test test/parapet/integrations/rindle_test.exs`
- `mix compile --warnings-as-errors`
- `mix run -e 'Mix.Task.run("verify.public_api")'`
