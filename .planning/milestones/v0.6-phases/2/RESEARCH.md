<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None explicitly found in CONTEXT.md (file not present). Adhering to project rules in GEMINI.md and phase scope.

### the agent's Discretion
None

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RUL-01 | System consumes `Rulestead` telemetry events for feature flag toggles. | Telemetry listener attached to `[:rulestead, :admin, :ruleset, :published]`, buffered in `Parapet.SystemEvent` |
| RUL-02 | Operator UI highlights proximate Rulestead flag changes on Incident pages. | Hybrid UI correlation via "Suspect Changes" hero card and inline `TimelineEntry` markers |
</phase_requirements>

# Phase 2: Rulestead Flag Correlation - Research

**Researched:** 2024-05-17
**Domain:** Incident Correlation, Telemetry Integration, SRE UI
**Confidence:** HIGH

## Summary

This phase integrates `Parapet` with `Rulestead` feature flag mutations via Telemetry. To avoid tight coupling and unnecessary data duplication, Parapet will implement a generic `Parapet.SystemEvent` schema to durably buffer system change events. A `SystemEvent.Pruner` GenServer will periodically prune events older than a configured retention window (e.g., 7 days) to limit storage footprint. When an incident is created, recent `SystemEvent` records within a configurable correlation window (e.g., 60 minutes) are persisted to the incident's timeline. The Operator UI will highlight these recent system changes in a distinct "Suspect Changes" hero card, while also adding them as timeline markers to aid the solo founder SRE.

**Primary recommendation:** Implement a bounded generic `SystemEvent` buffer populated via explicit Telemetry attachment and pruned via a built-in GenServer, avoiding hard coupling to external schemas or external queuing tools like Oban.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Rulestead Telemetry Capture | API / Backend | — | Dedicated adapter module (`Parapet.Integrations.Rulestead`) listens to external system telemetry. |
| Pre-Incident Event Buffer | Database / Storage | — | Bounded buffer (`Parapet.SystemEvent`) for system events needed for retroactive incident correlation. |
| Event Retention / Pruning | API / Backend | — | Built-in GenServer limits table bloat automatically without extra queues. |
| Incident Correlation | API / Backend | — | Core domain boundary (`Parapet.Spine`) manages TimelineEntry creation upon Incident generation. |
| UI Highlighting & Timeline | Frontend Server | — | LiveView components render "Suspect Changes" card and inline timeline nodes. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | ~> 1.0 | Event publishing/handling | Official standard for decoupled cross-library integration in Elixir. |
| `Ecto` | ~> 3.10 | Persistence | Standard data mapping layer in Elixir. |
| `Phoenix.LiveView`| ~> 0.20 | Operator UI | Standard stateful UI framework in Elixir ecosystem. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `GenServer` | OTP built-in | Pruning | For periodic cleanup of the `SystemEvent` table. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Parapet.SystemEvent` buffer via Telemetry | Rulestead native audit ledger direct query | Hard coupling to Rulestead's Ecto schemas; blind to other systems' changes (e.g., CI/CD). |
| Built-in GenServer Pruner | `Oban` Worker | Introduces a heavy third-party dependency just for internal GC. Built-in GenServer respects "batteries-included" SRE tool goals. |

## Architecture Patterns

### Recommended Project Structure
```
lib/parapet/
├── integrations/
│   └── rulestead.ex       # Telemetry attach/handle logic
├── spine/
│   ├── system_event.ex    # Bounded buffer schema
│   └── system_event_pruner.ex # GenServer for GC
└── operator/
    └── components.ex      # "Suspect Changes" card and timeline markers
```

### Pattern 1: Explicit Telemetry Attachment
**What:** The host application explicitly invokes the integration in their application start or telemetry wiring.
**When to use:** Integrating third-party system event capture into Parapet.
**Example:**
```elixir
# In host application's telemetry setup or Application.start/2
Parapet.Integrations.Rulestead.attach()
```

### Pattern 2: Generic System Event Buffer
**What:** A bounded database buffer for arbitrary system changes (`Parapet.SystemEvent`) that avoids tightly coupling to specific external library schemas.
**When to use:** Storing pre-incident actions (flag flips, deploys) for retroactive correlation when an incident eventually fires.

### Pattern 3: Hybrid UI Correlation
**What:** Presenting correlated events both as an actionable high-level summary ("Suspect Changes" card) and as part of the immutable chronological flow.
**When to use:** When rendering SRE incidents to minimize solo operator cognitive load while preserving forensic accuracy.

### Anti-Patterns to Avoid
- **Auto-attaching Telemetry:** Do not use `init/1` or application startup hooks in the Parapet library to automatically attach to external telemetry. Elixir libraries should avoid magic global state mutation; always require explicit host configuration (`.attach()`).
- **Tracking High-Volume Evaluation Telemetry:** Do not track individual flag evaluations (`:decide`, `:impression`). Track only administrative mutations (`:ruleset, :published`) to prevent database bloat and metric explosion.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-library event observation | Direct GenServer calls or polling Ecto tables | `:telemetry` | Erlang/Elixir's official mechanism for low-overhead, decoupled library introspection. |
| Purge scheduling | Custom Oban Workers for Parapet internals | Supervised `GenServer` (`SystemEvent.Pruner`) | Prevents Parapet from having a hard requirement on an external queuing library just for basic garbage collection. |

**Key insight:** Adopting standard OTP and telemetry mechanisms prevents dependency bloat while delivering robust SRE capabilities to a solo founder.

## Common Pitfalls

### Pitfall 1: Missing Scope Data
**What goes wrong:** Operators don't know if a flag flip affected all users or just one tenant.
**Why it happens:** Capturing just the flag name and ignoring the `target` or `percentage` payload from Rulestead.
**How to avoid:** Ensure the `SystemEvent` payload includes the scope (e.g., `global`, `tenant:acme`, `rollout:10%`).
**Warning signs:** Vague timeline entries that do not help with rapid RCA.

### Pitfall 2: Silent Storage Bloat
**What goes wrong:** `Parapet.SystemEvent` grows infinitely, filling up the host's Postgres database.
**Why it happens:** No built-in retention mechanism.
**How to avoid:** `Parapet.SystemEvent.Pruner` must be enabled by default and clear events older than the retention window (e.g., 7 days).
**Warning signs:** Slow timeline queries and large Ecto tables.

## Code Examples

### Telemetry Attachment & Event Handling
```elixir
defmodule Parapet.Integrations.Rulestead do
  @events [
    [:rulestead, :admin, :ruleset, :published]
  ]

  def attach do
    :telemetry.attach_many(
      "parapet-rulestead-integration",
      @events,
      &__MODULE__.handle_event/4,
      nil
    )
  end
  
  def handle_event([:rulestead, :admin, :ruleset, :published], measurements, metadata, _config) do
    # 1. Store as SystemEvent for correlation
    # Parapet.Spine.SystemEvent boundary logic goes here
    
    # 2. Emit Parapet metric for Grafana overlays
    :telemetry.execute([:parapet, :rulestead, :flag_change], measurements, metadata)
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Polling DB tables | `telemetry` event handlers | Elixir ~1.10 | Decoupled systems; external libraries don't need direct knowledge of Parapet. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Operator UI elements like "Suspect Changes" will be integrated into a single unified detail page. | Architecture / UI | The layout might become cluttered if too many correlation cards are stacked. |

## Open Questions

1. **(RESOLVED) Correlation Window Overlap**
   - What we know: Default correlation window is 60 minutes.
   - What's unclear: If multiple flag flips happen in 60 minutes, do we show all of them on the "Suspect Changes" card?
   - Recommendation: Yes, show all within the window to prevent omitting the actual root cause. The operator can visually filter them.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `telemetry` | Event capture | ✓ | ~> 1.0 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs`, `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUL-01 | Adapter buffers SystemEvent | unit | `mix test test/parapet/integrations/rulestead_test.exs` | ❌ |
| RUL-01 | Pruner deletes old events | unit | `mix test test/parapet/spine/system_event_pruner_test.exs` | ❌ |
| RUL-02 | Suspect card renders if changes | unit | `mix test test/parapet/operator/ui_test.exs` | ❌ |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Ecto Changesets for SystemEvent |
| V6 Cryptography | no | — |

## Sources

### Primary (HIGH confidence)
- `.planning/v0.6-REQUIREMENTS.md` - Verified phase requirements.
- `.planning/v0.6-phases/2/UI-SPEC.md` - Operator UI design and specifications.
- `.planning/v0.6-phases/2/RESEARCH.md` (original) - Retained the design decisions regarding `Parapet.SystemEvent` and explicitly ignoring evaluation telemetry.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/Phoenix ecosystem standards.
- Architecture: HIGH - Adheres directly to existing Parapet patterns and Elixir `telemetry` norms.
- Pitfalls: HIGH - Based on common SRE and storage bloat issues with event tracking.

**Research date:** 2024-05-17
**Valid until:** 2024-11-17
