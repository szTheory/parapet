<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Dependency & Packaging Strategy:** Single Monorepo with `Code.ensure_loaded?/1` guards. No separate Hex packages.
- **Adapter Activation Strategy:** Explicit Host Config. The host explicitly opts-in via their application tree or config (`Parapet.attach(adapters: [...])`).
- **UI Extensibility Seam:** Capability-Based UI Registration. Adapters register mitigation capabilities into Parapet's spine, and the host-generated Operator UI dynamically renders `Parapet.capabilities(:mitigation)`.

### the agent's Discretion
None explicitly listed.

### Deferred Ideas (OUT OF SCOPE)
None explicitly listed.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ECO-01 | System provides an optional integration adapter for Rulestead to track feature flag changes and enable flag-toggling mitigations via the Operator UI. | Supported by Code.ensure_loaded? guards, Telemetry handlers, and Capability Registry. |
| ECO-02 | System provides optional integration adapters for Mailglass and Chimeway to establish out-of-the-box deliverability SLIs. | Supported by Telemetry handler attachment mapping to standard Parapet SLI events. |
| ECO-03 | System provides optional integration adapters for Accrue (billing) and Rindle (media processing) to track business-specific journey health. | Supported by translating specific system metrics into SLI journey payloads. |
| ECO-04 | System strictly adheres to the "compile out cleanly" constraint, ensuring core functionality runs without any sibling libraries installed using dynamic module checks. | Enforced by wrapping adapter modules in `if Code.ensure_loaded?(TargetModule) do ... end`. |
| ECO-05 | System conceptually integrates with Threadline for durable audit history interoperability. | Achieved by mapping internal Parapet Tool Audits to Threadline's schema shapes. |
</phase_requirements>

# Phase 3: Sibling Ecosystem Integrations - Research

**Researched:** 2024-05-24
**Domain:** Elixir Integrations, Telemetry, and Dynamic Registration
**Confidence:** HIGH

## Summary

This phase implements optional ecosystem integrations (ECO-01 to ECO-05) without introducing hard dependencies. By leveraging Elixir's `Code.ensure_loaded?/1` guard, Parapet acts as a robust orchestrator that "compiles out" inactive integrations. The architecture relies on three primary pillars:
1.  **Guarded Integration Modules**: Modules under `Parapet.Integrations.*` that compile safely.
2.  **Explicit Host Activation**: A `Parapet.attach(adapters: [...])` configuration to invoke setup functions.
3.  **Dynamic Capability Registration**: A registry exposed via `Parapet.capabilities/1` to provide actionable mitigations to the Operator UI.

**Primary recommendation:** Follow the `Parapet.Integrations.Sigra` pattern for isolating integration telemetry mapping, while introducing an Agent-backed or Application-env capability registry for UI mitigations.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Adapter Guarding | Core / Macro | — | `Code.ensure_loaded?/1` ensures compilation without hard dependencies. |
| Telemetry Mapping | API / Backend | — | Adapters translate external telemetry to Parapet domain standards. |
| Action Registry | API / Backend | — | UI needs a dynamic list of active actions (mitigations) from loaded adapters. |
| Dynamic UI Rendering | Frontend (LiveView) | API / Backend | UI renders action forms dynamically based on capabilities registry. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | ~> 1.14 | Language | Host language for Parapet. |
| :telemetry | ~> 1.0 | Metrics & Events | Standard Erlang/Elixir event dispatch and attachment. |

## Architecture Patterns

### Recommended Project Structure
```
lib/
└── parapet/
    ├── integrations/
    │   ├── accrue.ex
    │   ├── chimeway.ex
    │   ├── mailglass.ex
    │   ├── rindle.ex
    │   ├── rulestead.ex
    │   └── threadline.ex
    └── capabilities.ex      # Registry for UI Extensibility
```

### Pattern 1: Optional Adapters (Compile Out Cleanly)
**What:** Wrapping integrations with compile-time checks so missing dependencies don't break compilation.
**When to use:** For all sibling ecosystem integration modules (ECO-04).
**Example:**
```elixir
if Code.ensure_loaded?(Rulestead) do
  defmodule Parapet.Integrations.Rulestead do
    @moduledoc "Optional adapter for Rulestead."
    
    def setup do
      # Attach telemetry
      :telemetry.attach("parapet-rulestead-flag", [:rulestead, :flag, :changed], &__MODULE__.handle_event/4, nil)
      
      # Register capabilities for Operator UI
      Parapet.Capabilities.register_mitigation(:rulestead, "toggle_flag", %{
        name: "Toggle Feature Flag",
        schema: [flag_name: :string, state: :boolean]
      })
    end
    
    def handle_event(event, measurements, metadata, _config) do
      # Safely dispatch Parapet Timeline entries or SLIs
    end
  end
end
```

### Pattern 2: Mitigation Capabilities (`Parapet.capabilities/1`)
**What:** An internal registry (e.g. Agent or Application Env) that collects available UI mitigations from activated adapters. The Operator UI loops over `Parapet.capabilities(:mitigation)` to render actionable buttons.
**When to use:** To populate the Operator Interface (UI-02) dynamically (ECO-01).
**Example:**
```elixir
defmodule Parapet.Capabilities do
  @doc "Returns registered capabilities by type (e.g., :mitigation)"
  def capabilities(:mitigation) do
    # Implementation reading from Agent/Registry populated by active adapters
    [
      %{adapter: :rulestead, id: "toggle_flag", name: "Toggle Feature Flag", schema: [...]}
    ]
  end
end
```

### Pattern 3: SLI & Timeline Registration
**What:** Adapters translate specific library events (e.g. Mailglass bounce) into Parapet's Timeline or SLO tracking domains.
**When to use:** ECO-02 and ECO-03 requirements.
**Example:**
```elixir
# In Parapet.Integrations.Mailglass
def handle_event([:mailglass, :delivery, :failure], measurements, metadata, _config) do
  # 1. Register a timeline entry for an open incident
  Parapet.Operator.record_note(open_incident, "Mail delivery failure: #{metadata.reason}", action_payload)
  
  # 2. Emit SLI failure telemetry for Parapet to track health
  :telemetry.execute([:parapet, :journey, :mail_delivery], %{duration: measurements.duration}, %{outcome: :failure})
end
```

### Anti-Patterns to Avoid
- **Hard `alias` outside guards:** Never `alias` or invoke sibling library functions outside of `if Code.ensure_loaded?(Mod)` blocks, as it will cause `UndefinedFunctionError` on host projects lacking the dependency.
- **Auto-registration:** Avoid running setup automatically via application start. Explicit `Parapet.attach(adapters: [:rulestead])` provides the host control and clarity.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Optional Dependency Checks | Custom module macros or `try/rescue` on compile | `if Code.ensure_loaded?(Mod)` | Native Elixir compiler support, completely excludes AST if false. |
| Event Mapping | Custom PubSub | `:telemetry.attach/4` | Standard ecosystem mechanism used by all Elixir libraries. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified by codebase review. | None |
| Live service config | None — verified by codebase review. | None |
| OS-registered state | None — verified by codebase review. | None |
| Secrets/env vars | None — verified by codebase review. | None |
| Build artifacts | None — verified by codebase review. | None |

## Common Pitfalls

### Pitfall 1: Telemetry Handler Exceptions
**What goes wrong:** A bug in an integration's `handle_event` crashes the calling process, impacting the host application (e.g., stopping a web request).
**Why it happens:** Telemetry executes synchronously in the caller's process.
**How to avoid:** Use `Parapet.Internal.SafeHandler` or explicitly wrap `rescue` blocks as seen in `Parapet.Integrations.Sigra`.

### Pitfall 2: Memory Leaks in Capability Registry
**What goes wrong:** Repeated reloading in `iex` or tests registers the same capability multiple times.
**Why it happens:** Registry insertion doesn't check for existing keys/IDs.
**How to avoid:** Ensure capability registration uses idempotent keys (e.g., `{adapter_name, action_id}`).

## Code Examples

### Standard Attach Method
```elixir
# In lib/parapet.ex
def attach(opts \\ []) do
  adapters = Keyword.get(opts, :adapters, [])
  
  Enum.each(adapters, fn
    :rulestead -> 
      if Code.ensure_loaded?(Parapet.Integrations.Rulestead), do: Parapet.Integrations.Rulestead.setup()
    :mailglass ->
      if Code.ensure_loaded?(Parapet.Integrations.Mailglass), do: Parapet.Integrations.Mailglass.setup()
    # ...
  end)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Optional hex packages | Monorepo + `Code.ensure_loaded?/1` | Project inception | Eliminates dependency hell, ensures lockstep updates, simpler host UX. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Mitigation actions will be executed synchronously via Operator UI. | Architecture | UI blocking if actions are slow; might need async tasks. |
| A2 | Operator UI form schemas for mitigations can be represented plainly (e.g. `[field: :type]`). | Architecture | Complex validations might require Ecto schemaless forms integration. |

## Open Questions

1. **Mitigation Execution Pipeline**
   - **Resolved:** Mitigations will be executed via a standard `{Module, :function, args}` MFA tuple stored in the `Parapet.Capabilities` registry, allowing the LiveView UI to safely `apply/3` the capability back to the adapter.

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | test/test_helper.exs |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ECO-01 | Rulestead adapter setup and telemetry | unit | `mix test test/parapet/integrations/rulestead_test.exs` | ❌ Wave 0 |
| ECO-02 | Mailglass/Chimeway telemetry | unit | `mix test test/parapet/integrations/mailglass_test.exs` | ❌ Wave 0 |
| ECO-03 | Accrue/Rindle telemetry | unit | `mix test test/parapet/integrations/accrue_test.exs` | ❌ Wave 0 |
| ECO-01 | Capability registry setup | unit | `mix test test/parapet/capabilities_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/parapet/integrations/rulestead_test.exs` — covers ECO-01
- [ ] `test/parapet/integrations/mailglass_test.exs` — covers ECO-02
- [ ] `test/parapet/integrations/chimeway_test.exs` — covers ECO-02
- [ ] `test/parapet/integrations/accrue_test.exs` — covers ECO-03
- [ ] `test/parapet/integrations/rindle_test.exs` — covers ECO-03
- [ ] `test/parapet/integrations/threadline_test.exs` — covers ECO-05
- [ ] `test/parapet/capabilities_test.exs` — covers dynamic registration

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | (Host app handles auth) |
| V3 Session Management | no | (Host app handles sessions) |
| V4 Access Control | yes | LiveView plugs / Host policies before rendering mitigations |
| V5 Input Validation | yes | Ecto changesets / schematic form validation for capability parameters |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsafe atom creation | Denial of Service | `String.to_existing_atom` or map parsing for UI inputs |
| Telemetry crash | Denial of Service | Rescue blocks in handlers (SafeHandler) |

## Sources

### Primary (HIGH confidence)
- `lib/parapet/integrations/sigra.ex` - Verified standard Parapet pattern for integrations
- `.planning/phases/3/3-CONTEXT.md` - Phase constraints

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/telemetry patterns
- Architecture: HIGH - Built upon proven Parapet internal patterns
- Pitfalls: HIGH - Documented Elixir telemetry issues

**Research date:** 2024-05-24
**Valid until:** 2024-12-31
