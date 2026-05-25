# Telemetry Event Schema

> #### Stable Contract {: .info}
>
> This telemetry reference is **stable** as of v1.0.0. Event names under
> `[:parapet, …]` are frozen — renaming or removing them is a semver-major change.
> Measurement and documented metadata keys may be extended in minor releases but
> will not be removed or renamed without a deprecation cycle. Parapet will never
> add a configurable `:event_prefix` option; all event names are static.
> See [Stability & Deprecation Policy](stability.html) for details.

Parapet emits telemetry as a public contract. Event names define the lifecycle seam, while metadata stays bounded and safe for downstream metrics, SLOs, and incident logic.

## Versioning Contract

The telemetry event schema version is tied to the package version. Renaming or removing event names, measurements, or documented metadata fields is a semver-major change. Adding new bounded fields or measurements may be done in a minor release.

## Label Safety

Phase 4 introduces a strict split between label-safe metadata and exact refs:

- Safe top-level metadata is limited to documented bounded fields such as `integration`, `provider`, `channel`, `queue`, `pipeline_stage`, `outcome`, `failure_class`, `delay_bucket`, `retry_state`, and `fault_plane`.
- Exact identifiers do not belong in top-level metadata. They are demoted into `metadata.refs` using `_ref` keys such as `message_ref`, `delivery_ref`, `job_ref`, or `webhook_ref`.
- Raw provider payloads, paths, tokens, and `*_id` values are not part of the public contract.

## Async And Delivery Families

### Delivery families

#### `[:parapet, :delivery, :outbound]`
Emitted when Parapet observes an outbound provider handoff attempt.

**Measurements:**
- `count` (integer) - Defaults to `1`.
- `duration_ms` (integer) - Duration of the observed upstream step in milliseconds when available.

**Metadata:**
- `integration` - Adapter name such as `:mailglass`.
- `provider` - Provider or delivery backend.
- `channel` - Delivery channel such as `:email` or `:notification`.
- `outcome` - Usually `:attempted` at this seam.
- `fault_plane` - Usually `:provider`.
- `refs` - Optional exact identifiers such as `message_ref` or `delivery_ref`.

#### `[:parapet, :delivery, :provider_feedback]`
Emitted when a provider response or reconciliation step yields a bounded delivery outcome.

**Measurements:**
- `count` (integer)
- `duration_ms` (integer)

**Metadata:**
- `integration`
- `provider`
- `channel`
- `outcome` - Bounded delivery outcomes: `attempted`, `provider_accepted`, `delivered`, `failed`, and supported extensions such as `bounced`, `complained`, `suppressed`.
- `failure_class` - Small bounded reason classification when relevant.
- `fault_plane` - Usually `:provider` or `:suppression`.
- `refs`

#### `[:parapet, :delivery, :webhook_ingest]`
Emitted when callback or webhook processing is the meaningful delivery seam.

**Measurements:**
- `count` (integer)
- `duration_ms` (integer)
- `delay_ms` (integer) - Optional raw measurement for timing, not a label.

**Metadata:**
- `integration`
- `provider`
- `channel`
- `outcome`
- `failure_class`
- `delay_bucket` - Bounded bucket derived from delay, not a raw value.
- `fault_plane` - Usually `:webhook`.
- `refs`

### Async families

#### `[:parapet, :async, :stage]`
Emitted for bounded async pipeline progress.

**Measurements:**
- `count` (integer)
- `duration_ms` (integer)

**Metadata:**
- `integration`
- `provider` - Optional when the upstream system has one.
- `queue`
- `pipeline_stage`
- `outcome` - Bounded async outcomes: `started`, `succeeded`, `retryable_failed`, `discarded`, `delayed`.
- `retry_state` - For example `first_attempt`, `retrying`, `exhausted`.
- `fault_plane` - Usually `:worker`.
- `refs`

#### `[:parapet, :async, :backlog]`
Emitted when the primary symptom is queue or backlog pressure.

**Measurements:**
- `count` (integer)
- `delay_ms` (integer) - Optional raw measurement for timing, not a label.

**Metadata:**
- `integration`
- `provider`
- `queue`
- `outcome`
- `delay_bucket`
- `fault_plane` - Usually `:backlog`.
- `refs`

#### `[:parapet, :async, :callback]`
Emitted when callback or reconciliation delay is distinct from internal backlog.

**Measurements:**
- `count` (integer)
- `delay_ms` (integer)

**Metadata:**
- `integration`
- `provider`
- `queue`
- `pipeline_stage`
- `outcome`
- `delay_bucket`
- `fault_plane` - Usually `:webhook`.
- `refs`

## Semantic Guarantees

- `provider_accepted` is not the same as `delivered`.
- `retryable_failed` is not the same as `discarded`.
- Callback or reconciliation delay is not the same as queue backlog.
- Public metadata is intentionally narrower than the upstream integration payloads.
