<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. **State Tracking (AI-HITL-01):** Scoria owns the durable state and is responsible for emitting `[:scoria, :workflow, :stale]` and `[:scoria, :workflow, :expired]` telemetry events natively. Parapet acts purely as an observer and avoids duplicating state or polling via Oban.
2. **Dual-Track Observability & Alerting (AI-HITL-02):** We are adopting a **Dual-Track Telemetry** pattern. 
   - *Track 1 (Alerting):* Parapet translates staleness events into low-cardinality Prometheus metrics (`scoria_workflow_stale_total`). Alertmanager handles threshold-based alerting (e.g., paging the operator only if a systemic spike occurs) to prevent incident fatigue.
   - *Track 2 (Evidence & Deep Linking):* Parapet simultaneously intercepts the event and synchronously writes a durable `Parapet.Evidence.ActionItem` to Ecto containing the exact high-cardinality `workflow_id`. The Operator UI reads directly from this table, ensuring flawless 100% deep-link availability without TSDB bloat or flaky log joins.
3. **Deep Linking (AI-HITL-03):** To avoid tightly coupling Parapet to Scoria's routing layer, Parapet will use a configurable MFA (`ui_url_resolver` in `config :parapet, :scoria`) to resolve Scoria's UI URLs dynamically from the Parapet Operator UI.
4. **ActionItem Lifecycle Sync:** We are adopting the **Telemetry for UX, Adapter for Truth** pattern to prevent state drift. `ActionItems` store an external reference (e.g., `external_id: "workflow_123"`). Scoria's resolution telemetry events (`[:scoria, :workflow, :resumed]`) act purely as cache-invalidation "hints", triggering an idempotent status check via the `Parapet.Integration.Scoria` adapter rather than blindly updating Parapet's database. This provides real-time UX without the risk of permanent zombie alerts if a telemetry event is dropped.

### the agent's Discretion
None specified.

### Deferred Ideas (OUT OF SCOPE)
None specified.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AI-HITL-01 | System monitors Scoria workflow approval pauses as durable HITL states, not generic queues. | Research defines `Parapet.Evidence.ActionItem` schema for durable pointer storage. |
| AI-HITL-02 | System can trigger alerts on stale or expiring workflow approval requests. | Research confirms Prom metrics approach via Dual-Track telemetry, incrementing `scoria_workflow_stale_total`. |
| AI-HITL-03 | System extends the LiveView Operator UI to deep-link into Scoria's durable evidence and approval UI. | Research maps MFA resolver `config :parapet, :scoria, :ui_url_resolver` strategy to prevent tight coupling. |
</phase_requirements>

# Phase 4: Workflow Approval Monitoring - Research

**Researched:** 2024-05-14
**Domain:** SRE, Telemetry, UI Integration
**Confidence:** HIGH

## Summary

This phase implements Parapet's capabilities to monitor, alert on, and manage stalled AI workflows in Scoria. To ensure maximum reliability and ease of use for solo operators, it employs a "Dual-Track Telemetry" approach. First, low-cardinality data feeds standard Prometheus metrics to power Alertmanager alerts. Simultaneously, a durable Ecto record (`ActionItem`) captures high-cardinality contexts like exact workflow IDs. 

Deep linking is achieved dynamically using an MFA-based config block, meaning Parapet needs zero knowledge of the host application's actual router or URL schemes. Finally, state is managed idempotently: Scoria remains the source of truth, and telemetry events act only as UX invalidation hints to avoid state drift.

**Primary recommendation:** Implement `Parapet.Evidence.ActionItem` alongside a telemetry intercept in `Parapet.Integrations.Scoria` that handles staleness and resumption using the "Adapter for Truth" pattern.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Staleness Telemetry Handling | API / Backend | — | `Parapet.Integrations.Scoria` maps incoming `[:scoria, :workflow, :stale]` to metrics and db inserts. |
| Alert Metrics Emission | API / Backend | — | Incrementing Prometheus counters must happen in the backend telemetry layer. |
| ActionItem Persistence | Database / Storage | — | `Parapet.Evidence.ActionItem` Ecto schema holds the durable pointer to the Scoria workflow. |
| UI Rendering & Deep Linking | Frontend Server (SSR) | — | Phoenix LiveView parses the ActionItem and dynamically resolves the URL using configured MFA. |
| State Synchronization | API / Backend | — | `[:scoria, :workflow, :resumed]` triggers idempotent status check via integration module, keeping UI correct. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `telemetry` | ~> 1.2 | Event interception | Erlang/Elixir standard for decoupled event handling. |
| `ecto` | ~> 3.10 | Durable storage | Standard Elixir data mapping and database wrapper. |
| `phoenix_live_view` | ~> 0.20 | Real-time UI | Parapet Operator UI standard. |

## Architecture Patterns

### Recommended Project Structure
```
lib/parapet/
├── spine/
│   └── action_item.ex         # New Ecto Schema for durable pointers
├── evidence.ex                # Add create_action_item/1 and resolve_action_item/1
├── integrations/
│   └── scoria.ex              # Add event handlers for :stale, :expired, :resumed
└── operator_ui/
    └── live/                  # Update to render ActionItems list with deep links
```

### Pattern 1: Dual-Track Telemetry
**What:** Splitting high-volume telemetry events into separate paths: low-cardinality data for metrics (Prometheus) and high-cardinality data for durable storage (Ecto ActionItem).
**When to use:** When you need both alerting on aggregate trends (which fails with high-cardinality) and actionable evidence containing specific IDs (which TSDBs don't handle well).
**Example:**
```elixir
def handle_event([:scoria, :workflow, :stale], measurements, metadata, _config) do
  # Track 1: Low Cardinality Metrics
  :telemetry.execute([:parapet, :scoria, :metrics, :stale], measurements, Map.take(metadata, [:workflow_type]))
  
  # Track 2: Durable Evidence Pointer
  Parapet.Evidence.create_action_item(%{
    title: "Workflow Stale",
    integration: "scoria",
    external_id: metadata.workflow_id
  })
end
```

### Pattern 2: MFA Configured Resolution (ui_url_resolver)
**What:** Storing `{Module, :function, [args]}` in the application config to defer routing knowledge to the host application.
**When to use:** When a generic library or operator UI needs to deep link into host application routes it doesn't own.
**Example:**
```elixir
def deep_link_url(action_item) do
  {mod, func, args} = Application.get_env(:parapet, :scoria)[:ui_url_resolver]
  apply(mod, func, [action_item.external_id | args])
end
```

### Anti-Patterns to Avoid
- **State Duplication via Telemetry:** Do not treat `[:scoria, :workflow, :resumed]` as the absolute source of truth to close an ActionItem. Telemetry events can be dropped. Use them as cache-invalidation hints to trigger an idempotent check against Scoria.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deep Link Routing | Hardcoding host app routes in Parapet | MFA configuration | Parapet should remain host-app agnostic; coupling paths breaks installation portability. |
| Idempotent Sync | Complex background worker sync | Telemetry triggers + explicit Scoria query | Prevents split-brain state without heavy periodic polling. |

## Common Pitfalls

### Pitfall 1: Telemetry Event Drops Causing Zombie Alerts
**What goes wrong:** A workflow is approved in Scoria, but the `[:scoria, :workflow, :resumed]` telemetry event is dropped (e.g., node restart, queue overflow). The Parapet ActionItem remains `open` forever.
**Why it happens:** Treating telemetry as a guaranteed delivery mechanism for state machines.
**How to avoid:** Implement "Adapter for Truth". Parapet must have a way to idempotently query the integration (`Parapet.Integrations.Scoria.check_status/1`) periodically or on UI load, to self-heal.
**Warning signs:** Operators complaining about ActionItems in the UI that have already been resolved.

## Code Examples

### Deep Link Resolver Invocation
```elixir
defmodule Parapet.OperatorUI.ActionItemComponent do
  use Phoenix.Component

  def link(assigns) do
    # Assuming config :parapet, :scoria, ui_url_resolver: {MyAppWeb.Router.Helpers, :scoria_workflow_path, [MyAppWeb.Endpoint, :show]}
    {mod, fun, args} = Application.get_env(:parapet, :scoria)[:ui_url_resolver]
    url = apply(mod, fun, args ++ [assigns.item.external_id])
    
    ~H"""
    <a href={url}>Review Workflow</a>
    """
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Poll databases for stale records | Emit telemetry events for staleness | Phase 4 | Removes database load; reacts in real-time. |
| High cardinality in Prometheus | Dual-track telemetry (Prom + Ecto) | Phase 4 | Protects TSDB memory while preserving debuggability. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `telemetry` is already available and installed. | Standard Stack | [ASSUMED] High risk if missing. Verified via `parapet.ex` and `integrations/scoria.ex` which use it. |
| A2 | Operator UI uses Phoenix LiveView. | Standard Stack | [ASSUMED] Medium risk if it uses raw controllers, but DECISIONS.md explicitly calls it "LiveView Operator UI". |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AI-HITL-01 | ActionItem schema created | unit | `mix test test/parapet/spine/action_item_test.exs` | ❌ Wave 0 |
| AI-HITL-02 | Telemetry metrics emitted | unit | `mix test test/parapet/integrations/scoria_test.exs` | ✅ Wave 0 (partially) |
| AI-HITL-03 | LiveView deep link resolves MFA | integration | `mix test test/parapet/operator_ui_integration_test.exs` | ✅ Wave 0 (partially) |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/parapet/spine/action_item_test.exs` — covers AI-HITL-01
- [ ] `test/parapet/evidence/action_item_test.exs` — covers context boundary

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | LiveView `on_mount` authentication hooks check Operator role |
| V5 Input Validation | yes | Ecto Changesets validate ActionItem fields |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS in UI | Tampering | Phoenix HTML escaping |
| SSRF via MFA configs | Elevation of Privilege | MFA configs are read from compiled `sys.config`, meaning only developers can set them, not users. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/4/DECISIONS.md` - Verified architecture decisions and telemetry behavior.
- `.planning/milestones/v0.4-REQUIREMENTS.md` - Verified requirement IDs and expectations.
- `lib/parapet/integrations/scoria.ex` - Checked existing integration patterns.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Verified standard Phoenix/Elixir tools.
- Architecture: HIGH - Fully derived from provided explicit decisions.
- Pitfalls: HIGH - Known issue with telemetry delivery guarantees.

**Research date:** 2024-05-14
**Valid until:** 30 days
