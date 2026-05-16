# Phase 2: Deepened Journey Integrations - Research

**Researched:** `date +%Y-%m-%d`
**Domain:** Telemetry Integration and Operator UI
**Confidence:** HIGH

## Summary

This phase deepens Parapet's integrations by explicitly defining and capturing "Critical Journeys" for Auth (Sigra) and Billing (Accrue). The goal is to move from basic telemetry stubs to actionable, SLO-backed metric definitions, and to surface these journeys directly in the Parapet Operator UI to reduce Mean Time To Mitigate (MTTM) for solo founders. 

**Primary recommendation:** Introduce a `Critical Journeys` section to the Operator UI (`operator_live.ex.eex`), expand `Parapet.Integrations.Sigra` and `Parapet.Integrations.Accrue` to handle standardized `signup`, `checkout`, and `webhook` telemetry shapes, and define explicit telemetry metrics via a new `Parapet.Metrics.Journey` module.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Telemetry Translation | API / Backend | — | Adapters in `lib/parapet/integrations/` handle standardizing upstream events safely. |
| Metrics Definition | API / Backend | — | Defined in `Parapet.Metrics` using `Telemetry.Metrics` standard formats. |
| Critical Journeys UI | Frontend Server (SSR) | — | LiveView Operator UI (`operator_live.ex`) owns rendering the status/list of these journeys. |
| SLO Tracking | Database / Storage | API / Backend | Existing `Parapet.SLO` defines the rules, UI pulls definitions to render context. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `telemetry_metrics` | > 0.6.1 | Metric Definitions | Core standard in Elixir ecosystem. |
| `phoenix_live_view` | > 0.20.0 | Operator UI | Standard for interactive dashboards in Phoenix. |

## Architecture Patterns

### System Architecture Diagram
```
[Upstream Libraries (Sigra, Accrue)] 
       | (Emit native telemetry)
       v
[Parapet Integrations (sigra.ex, accrue.ex)]
       | (Translate & sanitize PII)
       v
[Parapet Journey Telemetry ([:parapet, :journey, :*])]
       |
       +--> [Parapet.Metrics.Journey] (Prometheus Counters/Distributions)
       |
       +--> [Parapet Operator UI] (LiveView UI displaying Critical Journeys)
```

### Pattern 1: Telemetry Signature Translation
**What:** Mapping upstream library telemetry to standardized `[:parapet, :journey, *]` events, strictly separating low-cardinality tags from high-cardinality metadata.
**When to use:** In integration adapters (`Sigra`, `Accrue`).
**Example:**
```elixir
defp process_event([:sigra, :auth, :signup, state], measurements, metadata)
     when state in [:completed, :failed] do
  outcome = if state == :completed, do: :success, else: :failure
  :telemetry.execute(
    [:parapet, :journey, :signup],
    %{duration: measurements.duration},
    %{outcome: outcome, provider: metadata.provider}
  )
end
```

### Anti-Patterns to Avoid
- **Passing PII to Metrics:** Avoid including `user_id` or `account_id` in low-cardinality `Telemetry.Metrics` tags to prevent cardinality explosion in Prometheus. Keep them in high-cardinality wide events instead.
- **Generic Dashboards:** Operator UI should avoid generic graphs; focus on specific, named "Journeys" with clear Good/Total SLO states.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UI State Management | Custom GenServers for UI state | `Phoenix.LiveView` + existing `Parapet.Operator` | Parapet already has robust Operator tooling; extending the queue/detail views is cleaner. |
| Metrics definitions | Custom ETS counters | `Telemetry.Metrics` | Hooks directly into PromEx / Prometheus natively. |

## Common Pitfalls

### Pitfall 1: Missing Webhook Latency Context
**What goes wrong:** Webhooks fail silently or get delayed, causing data drift without triggering standard HTTP SLOs.
**Why it happens:** Webhooks are async, often processed in Oban or separate queues, bypassing HTTP metrics.
**How to avoid:** Explicitly track `[:accrue, :billing, :webhook, :received]` vs `:processed` to establish latency, and track `:failed` for explicit error rates. Ensure `Accrue` adapter watches these events.

### Pitfall 2: Operator UI Clutter
**What goes wrong:** Adding generic "Auth" metrics graphs pollutes the Operator UI, causing cognitive overload.
**Why it happens:** Treating the Operator UI as a Grafana replacement.
**How to avoid:** The LiveView UI should focus strictly on "Critical Journeys" — a top-level list of Journeys (Login, Signup, Checkout, Webhooks) and their current binary SLO state or defined runbooks, pivoting to details on click.

## Code Examples

### Standard Metric Definition
```elixir
def metrics do
  import Telemetry.Metrics

  [
    counter("parapet.journey.signup.count",
      event_name: [:parapet, :journey, :signup],
      tags: [:outcome, :provider],
      description: "Total number of signup attempts"
    ),
    distribution("parapet.journey.billing.checkout.duration",
      event_name: [:parapet, :journey, :billing, :checkout],
      measurement: :duration,
      tags: [:outcome, :plan],
      description: "Duration of checkout processes"
    ),
    distribution("parapet.journey.billing.webhook.duration",
      event_name: [:parapet, :journey, :billing, :webhook],
      measurement: :duration,
      tags: [:outcome, :event_type],
      description: "Latency of webhook processing"
    )
  ]
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic error graphs | Critical Journeys Dashboard | Parapet v0.5 | Immediate mapping of user harm (SLO burn) to specific business flows. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Operator UI will query existing SLO definitions to render the Journeys widget. | Summary | If data is not accessible, UI will be out of sync with real metrics, or require a separate backend to hydrate LiveView. |

## Open Questions (RESOLVED)

1. **Journeys UI State Hydration**
   - What we know: Operator UI currently renders from `Parapet.Operator` via the DB (Incidents/Action Items).
   - What's unclear: How exactly will the `Critical Journeys Dashboard` get its current metric values? Does it query Prometheus, read `Parapet.SLO`, or keep an internal rolling window via `Telemetry` listeners?
   - Decision: For Phase 2, we will list the critical journeys statically defined via `Parapet.SLO` and link to their respective dashboards/runbooks. We will pass this static state (statically rendering SLO links and statuses) to the LiveView. This resolves the question by choosing static hydration initially.

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)
