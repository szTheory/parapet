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

## Recovery Action Family (Experimental)

> #### Experimental {: .warning}
>
> This event family is **experimental** in v1.x. Event names, measurement keys, and
> metadata keys may change in a minor release with a single CHANGELOG entry. See
> [Stability & Deprecation Policy](stability.html) for details.

Parapet emits this family when an operator or automation takes a recovery action via the
Preview → Confirm flow. The contract module `Parapet.Telemetry.RecoveryAction` provides
machine-readable introspection of the family, its metadata keys, and its closed vocabularies.

### `[:parapet, :operator, :recovery_action, :previewed]`

Emitted when an operator opens a Preview panel for a recovery action.

**Measurements:**
- `count` (integer) - Defaults to `1`.

**Metadata:**
- `capability_id` - Atom from the registered capabilities allowlist.
- `action_kind` - One of `"operator"`, `"automation"`, `"escalation"`.
- `outcome` - Always `:previewed` at this seam.
- `actor_kind` - `:human` or `:system`.

### `[:parapet, :operator, :recovery_action, :preview_failed]`

Emitted when the Preview render itself errors (e.g. capability lookup or dry-run failure).

**Measurements:**
- `count` (integer) - Defaults to `1`.

**Metadata:**
- `capability_id`
- `action_kind`
- `outcome` - Always `:failed` at this seam.
- `failure_class` - One of `:precondition_failed`, `:provider_unavailable`, `:partial_failure`, `:internal_error`.
- `actor_kind`

### `[:parapet, :operator, :recovery_action, :confirmed]`

Emitted when the operator clicks Confirm (before claim acquisition).

**Measurements:**
- `count` (integer) - Defaults to `1`.

**Metadata:**
- `capability_id`
- `action_kind`
- `outcome` - Always `:confirmed` at this seam.
- `actor_kind`

### `[:parapet, :operator, :recovery_action, :short_circuited]`

Emitted when a Confirm request is rejected by a gate (preview expired, circuit breaker open,
target refs drift, or incident already resolved).

**Measurements:**
- `count` (integer) - Defaults to `1`.

**Metadata:**
- `capability_id`
- `action_kind`
- `outcome` - Always `:short_circuited` at this seam.
- `short_circuit_reason` - One of `:incident_resolved`, `:breaker_open`, `:preview_expired`, `:target_refs_drift`.
- `actor_kind`

### `[:parapet, :operator, :recovery_action, :conflicted]`

Emitted when `ClaimService` returns `{:conflicted, claim_id}` (another node or operator
holds an active claim for the same action).

**Measurements:**
- `count` (integer) - Defaults to `1`.

**Metadata:**
- `capability_id`
- `action_kind`
- `outcome` - Always `:conflicted` at this seam.
- `actor_kind`

### `[:parapet, :operator, :recovery_action, :executed]` (span family)

Emitted as a `:telemetry.span/3` triplet covering the capability `execute/2` call. Three
sub-event tuples are emitted in sequence:

- `[:parapet, :operator, :recovery_action, :executed, :start]`
- `[:parapet, :operator, :recovery_action, :executed, :stop]`
- `[:parapet, :operator, :recovery_action, :executed, :exception]` (on error)

**Measurements:**
- `:start` sub-event: `system_time` (integer) — monotonic system time at execution start.
- `:stop` and `:exception` sub-events: `duration_ms` (integer) and `duration_native` (integer).

`duration_ms` and `duration_native` are the project's measurement convention — the project
instrumenter converts the raw `:telemetry.span/3` `duration` (native units) into both keys
before downstream subscribers see the payload.

**Metadata (applied to all three sub-events):**
- `capability_id`
- `action_kind`
- `outcome` - One of `:succeeded`, `:failed` on `:stop`/`:exception`; absent on `:start`.
- `failure_class` - Present when `outcome` is `:failed`.
- `actor_kind`

### Closed Vocabularies

The following atom vocabularies are frozen as of v1.1. Adding new atoms is additive (minor
version change); removing or renaming is breaking (major version change). See
[Stability & Deprecation Policy](stability.html) for details.

- **`outcome`**: `:previewed`, `:confirmed`, `:short_circuited`, `:conflicted`, `:succeeded`, `:failed`
- **`short_circuit_reason`**: `:incident_resolved`, `:breaker_open`, `:preview_expired`, `:target_refs_drift`
- **`failure_class`**: `:precondition_failed`, `:provider_unavailable`, `:partial_failure`, `:internal_error`
- **`actor_kind`**: `:human`, `:system`
- **`action_kind`**: `"operator"`, `"automation"`, `"escalation"`
- **`refs` keys**: `:incident_ref`, `:claim_ref`, `:step_ref`, `:preview_ref`
