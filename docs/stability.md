# Stability & Deprecation Policy

Parapet maintains a three-tier stability system so adopters know exactly what they can
rely on in their SRE tooling and what may still evolve. This document enumerates every
public module's tier, defines the semver promise, distinguishes breaking from additive
changes, and specifies the full deprecation cycle.

## Stability Tiers

| Tier | Signal (ExDoc Callout) | Semver Guarantee |
|------|------------------------|-----------------|
| **Stable** | `> #### Stable {: .info}` | No breaking changes without a major-version bump + a full deprecation cycle. Adoption is safe for production integrations. |
| **Experimental** | `> #### Experimental {: .warning}` | May change in a minor release with a single CHANGELOG entry before any breaking change. Useful for early adopters willing to follow changes. |
| **Internal** | `Parapet.Internal.*` namespace or `@moduledoc false` | No guarantees. Not part of the public API surface. May change or disappear at any time. |

## Public API Surface Enumeration

### Stable Modules

These modules carry the `> #### Stable {: .info}` callout. Their public function signatures,
callback contracts, and telemetry event names will not change without a major-version bump
and a full deprecation cycle.

| Module | Description |
|--------|-------------|
| `Parapet` | Primary activation API (`attach/1`) |
| `Parapet.Integration` | Uniform adapter behaviour for `Parapet.attach/1` |
| `Parapet.SLO.Provider` | Core SLO provider behaviour |
| `Parapet.SLO.SliceSpec` | SLO slice specification struct |
| `Parapet.Runbook` | Runbook DSL for structured incident response |
| `Parapet.Escalation.Policy` | Escalation policy behaviour |
| `Parapet.Notifier` | Notifier behaviour for incident broadcasts |
| `Parapet.Evidence` | Core evidence recording API |
| `Parapet.Operator` | Operator dashboard and action surface |
| `Parapet.Deploy` | Deploy correlation marker (`mark/1`) |
| `Parapet.SLO.StarterPack.WebSaaS` | One-line WebSaaS SLO registration pack |
| `Parapet.SLO.StarterPack.DeliverySaaS` | One-line DeliverySaaS SLO registration pack |
| `Parapet.Telemetry.AsyncDelivery` | Machine-readable async/delivery telemetry contract |

### Experimental Modules

These modules carry the `> #### Experimental {: .warning}` callout. Their APIs may change
in a minor release; a single CHANGELOG entry will accompany any breaking change.

| Module | Description |
|--------|-------------|
| `Parapet.MCP.Server` | Read-only MCP server surface |
| `Parapet.MCP.PrometheusClient` | Prometheus query client for MCP |
| `Parapet.Automation.CircuitBreaker` | Ecto-backed circuit breaker for mitigations |
| `Parapet.Automation.ClaimService` | Action claim and idempotency service |
| `Parapet.Automation.Executor` | Async runbook execution via Oban |
| `Parapet.Metrics.AsyncDelivery` | Async/delivery Prometheus metrics |
| `Parapet.Metrics.Ecto` | Ecto query Prometheus metrics |
| `Parapet.Metrics.ExemplarStore` | Exemplar storage for trace correlation |
| `Parapet.Metrics.ExemplarTelemetry` | Exemplar telemetry bridge |
| `Parapet.Metrics.HTTP` | HTTP request Prometheus metrics |
| `Parapet.Metrics.Oban` | Oban job Prometheus metrics |
| `Parapet.Metrics.Probe` | Probe run Prometheus metrics |
| `Parapet.Metrics.PrometheusFormatter` | Prometheus text format encoder |
| `Parapet.Metrics.Rulestead` | Rulestead flag change metrics |
| `Parapet.Metrics.Scoria` | Scoria eval Prometheus metrics |
| `Parapet.Metrics.Sigra` | Sigra journey Prometheus metrics |
| `Parapet.Metrics.Validator` | Compile-time label cardinality validator |
| `Parapet.Metrics.Accrue` | Accrue billing Prometheus metrics |
| `Parapet.Probe` | Synthetic probe scheduler and runner |
| `Parapet.Probe.NativeScheduler` | Native Elixir probe scheduler |
| `Parapet.Probe.ObanScheduler` | Oban-backed probe scheduler |
| `Parapet.Evidence.Archiver` | Resolved incident archiver |
| `Parapet.Evidence.Retrospective` | Automated retrospective generator |
| `Parapet.Evidence.ArchiveWorker` | Oban worker for archive operations |
| `Parapet.Integrations.Accrue` | Accrue billing integration adapter |
| `Parapet.Integrations.Chimeway` | Chimeway notification integration adapter |
| `Parapet.Integrations.Mailglass` | Mailglass email integration adapter |
| `Parapet.Integrations.Rindle` | Rindle media processing integration adapter |
| `Parapet.Integrations.Rulestead` | Rulestead feature flag integration adapter |
| `Parapet.Integrations.Scoria` | Scoria AI observability integration adapter |
| `Parapet.Integrations.Sigra` | Sigra identity integration adapter |
| `Parapet.Integrations.Threadline` | Threadline compliance sync integration adapter |
| `Parapet.Notifier.Slack` | Slack notification adapter |
| `Parapet.Notifier.Teams` | Microsoft Teams notification adapter |
| `Parapet.Notifier.ObanWorker` | Oban worker for async notification dispatch |
| `Parapet.Escalation.Worker` | Oban worker for escalation policy dispatch |
| `Parapet.Plug.MCP` | Phoenix Plug for MCP endpoint |
| `Parapet.Plug.Webhook` | Phoenix Plug for Alertmanager webhook receiver |
| `Parapet.Plug.Metrics` | Phoenix Plug for Prometheus metrics endpoint |
| `Parapet.Operator.ActionPayload` | Action payload schema for operator mutations |
| `Parapet.Operator.WorkbenchContract` | Workbench computed view contract |
| `Parapet.Capabilities` | Capability detection and feature flags |
| `Parapet.Spine.Incident` | Ecto schema: Incident |
| `Parapet.Spine.TimelineEntry` | Ecto schema: Timeline Entry |
| `Parapet.Spine.ToolAudit` | Ecto schema: Tool Audit |
| `Parapet.Spine.ActionItem` | Ecto schema: Action Item |
| `Parapet.Spine.ActionClaim` | Ecto schema: Action Claim |
| `Parapet.Spine.SystemEvent` | Ecto schema: System Event |
| `Parapet.Spine.SystemEventPruner` | System event pruning worker |
| `Parapet.Spine.AlertProcessor` | Alertmanager alert-to-incident processor |
| `Parapet.SLO` | SLO registry module (contains deprecated `define/2`) |
| `Parapet.SLO.HTTP` | HTTP SLO preset slice module |
| `Parapet.SLO.LoginJourney` | Login journey SLO preset slice module |
| `Parapet.SLO.Oban` | Oban job SLO preset slice module |
| `Parapet.SLO.ChimewayDelivery` | Chimeway delivery SLO preset slice module |
| `Parapet.SLO.MailglassDelivery` | Mailglass delivery SLO preset slice module |
| `Parapet.SLO.RindleAsync` | Rindle async SLO preset slice module |
| `Parapet.SLO.ScoriaEval` | Scoria eval SLO preset slice module |
| `Parapet.SLO.Generator` | PromQL alert rule generator |

### Internal (Excluded from Gate)

These modules are excluded from the `mix verify.public_api` gate. They have no stability
guarantees and are not part of the public API surface.

| Module | Reason |
|--------|--------|
| `Parapet.Internal.*` | `Parapet.Internal.*` namespace — implementation details |
| `Parapet.TestSupport.*` | Test scaffolding — not for adopter use |
| `Parapet.SLO.Resolvable` | Internal protocol — excluded by `.Resolvable.` gate filter |

## Semver Promise

For **Stable** modules: Parapet follows [Semantic Versioning 2.0.0](https://semver.org).

- **Major version bump** (`1.x.x → 2.0.0`): May contain breaking changes. Every breaking
  change must first go through a full deprecation cycle (see below).
- **Minor version bump** (`1.0.x → 1.1.0`): New functions, new optional opts, new telemetry
  measurement/metadata keys may be added. Nothing is removed or renamed.
- **Patch version bump** (`1.0.0 → 1.0.1`): Bug fixes only. No API surface changes.

For **Experimental** modules: a single CHANGELOG entry noting the change before the release
that contains it is the only commitment. Breaking changes may ship in a minor release.

## What Counts as Breaking vs Additive

### Breaking (requires major bump for Stable modules)

- Renaming or removing a public function or callback
- Changing the arity of a public function
- Changing the return type or shape of a public function
- Removing or renaming a telemetry event name under `[:parapet, …]`
- Removing or renaming a documented telemetry measurement key
- Removing or renaming a documented telemetry metadata key
- Changing the atoms in an outcome vocabulary (e.g., `:delivered` → `:sent`)

### Additive (allowed in minor releases)

- Adding new public functions to a Stable module
- Adding new optional keys to an opts keyword list
- Adding new telemetry measurement keys to an existing event
- Adding new telemetry metadata keys to an existing event
- Adding new telemetry event families
- Adding new modules at any tier

## Deprecation Cycle

Parapet uses a three-stage deprecation cycle for Stable-tier functions:

1. **Soft deprecation** — `@doc deprecated: "Use X instead"` added to the function.
   Appears in ExDoc as a deprecation notice. A CHANGELOG entry is included in the release.
   No compile-time warning. The replacement must already exist.

2. **Hard deprecation** — `@deprecated "Use X instead"` replaces the soft deprecation (or
   is added directly for a full-release cycle). Emits a compile-time warning at every call
   site. The replacement must already exist. Must remain in place for **at least one minor
   release** before removal is considered.

3. **Removal** — Only at a **major version bump**. The function is deleted. The deprecation
   window (steps 1–2) must have been complete before the major bump.

For **Experimental** modules: a single CHANGELOG entry in the release that contains the
breaking change is sufficient. No multi-stage deprecation cycle is required.

## Telemetry Contract

The `[:parapet, …]` telemetry event surface is frozen as of v1.0.0. Telemetry events are
treated as part of the public API with the same semver guarantees as Stable module functions.

- **Event names are frozen** — renaming or removing any `[:parapet, …]` event name is a
  semver-major change.
- **Measurement and metadata keys are additive-only** — new keys may be added in minor
  releases; existing documented keys will not be removed or renamed without a deprecation cycle.
- **No configurable `:event_prefix`** — Parapet will never add a configurable `:event_prefix`
  option. All event names are static. This prevents the registry fragmentation seen when
  libraries allow event name customization (the Oban v2.10 lesson).

See the [Telemetry Reference](telemetry.html) for the complete list of event families,
measurements, and metadata keys.

## Deprecation Register

This register tracks all current deprecations. It is updated at each release that introduces
or advances a deprecation.

| Module / Function | Kind | Replacement | Deprecation Stage | Removal Target |
|-------------------|------|-------------|-------------------|---------------|
| `Parapet.SLO.define/2` | Hard `@deprecated` | `Parapet.SLO.Provider` — implement the behaviour and pass the module to `Parapet.attach/1` | Hard deprecation (compile-time warning active) | Next major version |

### `Parapet.SLO.define/2` deprecation window

`Parapet.SLO.define/2` is in **hard deprecation** as of v1.0.0. Call sites will see a
compile-time warning:

```
Parapet.SLO.define/2 is deprecated. Use a Parapet.SLO.Provider module instead.
```

The replacement is `Parapet.SLO.Provider` — define a module that implements the
`Parapet.SLO.Provider` behaviour and register it via `Parapet.attach/1`:

```elixir
defmodule MyApp.MySLOProvider do
  @behaviour Parapet.SLO.Provider

  @impl true
  def slos do
    [
      %Parapet.SLO.SliceSpec{
        name: :my_slo,
        objective: 99.9,
        # ...
      }
    ]
  end
end

# In your application start or Parapet.attach/1 call:
Parapet.attach(slo_providers: [MyApp.MySLOProvider])
```

`Parapet.SLO.define/2` will be removed at the next major version bump.
