# Phase 2: Runbooks & Automated Mitigations - Research

**Researched:** $(date +"%Y-%m-%d")
**Domain:** Elixir DSL, Ecto Schema Migrations, Phoenix LiveView, Immutable Audit Trail
**Confidence:** HIGH

## Summary

This research outlines the technical implementation for Phase 2, fulfilling the RUNBOOK-01 to RUNBOOK-04 requirements. We will implement `Parapet.Runbook` as a module-based DSL using Elixir macros. To uphold Parapet's core principle of "Immutable Facts", runbooks will be snapshot into a JSON payload (`runbook_data` as `:map`) on the `Incident` record when the alert is first processed. The UI will render this snapshot, and operator mitigations will be securely dispatched via `Parapet.Operator`, durably recording a `ToolAudit` for every execution.

**Primary recommendation:** Use a macro-based DSL that compiles to a static schema map, snapshot the schema onto `Incident` at creation, and use `String.to_existing_atom/1` for secure, audited dynamic dispatch of one-click mitigations.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Runbook DSL (`Parapet.Runbook`) | Core API / Backend | — | Elixir macros provide compile-time guarantees and developer ergonomics for defining standard runbooks. |
| Runbook Mapping & Storage | Database / Storage | Core API / Backend | The `runbook_data` snapshot belongs in the `parapet_incidents` table (JSONB/map) to preserve immutable history. |
| Runbook Viewer UI | Frontend Server (SSR) | — | Phoenix LiveView components inside the Operator UI render the runbook snapshot. |
| One-Click Mitigations | Core API / Backend | Database | Safely dispatches arbitrary host-app logic while persisting `ToolAudit` records in the same transaction. |

## User Constraints

<user_constraints>
### Locked Decisions
- RUNBOOK-01: System provides a DSL (`Parapet.Runbook`) to define structured runbooks with explicit steps, descriptions, and required evidence.
- RUNBOOK-02: System allows mapping specific runbooks to specific SLOs or alert names, ensuring they are automatically attached when an incident is created.
- RUNBOOK-03: System Operator UI displays the attached runbook interactively on the Incident detail page.
- RUNBOOK-04: System provides a mechanism for "one-click mitigations" directly from the runbook UI, durably recorded via a Tool Audit log.
- All actions must be durably recorded and preserve immutable historical facts (Parapet's core design).

### the agent's Discretion
- Implementation pattern for the DSL (chose macros generating static schema).
- Implementation pattern for storing the association (chose full JSON snapshot over string reference).

### Deferred Ideas (OUT OF SCOPE)
- N/A
</user_constraints>

## Phase Requirements

<phase_requirements>
| ID | Description | Research Support |
|----|-------------|------------------|
| RUNBOOK-01 | DSL for runbooks | Defined `Parapet.Runbook` macro-based DSL pattern. |
| RUNBOOK-02 | Mapping runbooks to incidents | Designed DB migration for `:map` `runbook_data` on `Incident` and integration in `AlertProcessor`. |
| RUNBOOK-03 | Interactive UI | Outlined LiveView components extension in `operator_detail_live.ex.eex`. |
| RUNBOOK-04 | One-click mitigations | Defined safe dynamic dispatch via `Parapet.Operator` and `ToolAudit` generation. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir Macros | Built-in | DSL implementation | Standard idiomatic approach for declarative configurations (like Ecto/Plug). |
| Ecto `:map` type | Built-in | Snapshot storage | Maps seamlessly to Postgres JSONB, perfect for storing runbook schemas immutably. |
| Phoenix LiveView | Built-in | Operator UI | Standard for Parapet's operator UI; allows server-side handling of mitigation clicks. |

## Architecture Patterns

### System Architecture Diagram

```text
[Webhook/Alert] --> (AlertProcessor) 
                        |
                        v
                Lookup SLO runbook module
                        |
                        v
[runbook.ex] --> (Call __runbook_schema__())
                        |
                        v
                Insert Incident (w/ runbook_data snapshot JSON)
                        |
                        v
[LiveView UI] <-- Render runbook_data
                        |
                        v
[Operator Clicks "Execute"] --> (Parapet.Operator.execute_runbook_step)
                                       |
                                       v
                             (Apply Mitigation Callback on Module)
                                       |
                                       v
                           [Evidence.run_operator_command]
                                       |
                                       +--> Insert TimelineEntry
                                       +--> Insert ToolAudit
```

### Pattern 1: Declarative Macro DSL
**What:** `Parapet.Runbook` uses module attributes to accumulate steps at compile-time, emitting a `__runbook_schema__()` function.
**When to use:** For defining runbooks. It provides a clean syntax for developers in the host application.

### Pattern 2: Immutable Snapshotting
**What:** The `runbook_data` (JSON map) is attached to the `Incident` database record at creation time, rather than just storing a module name and fetching it dynamically on read.
**When to use:** Whenever associating mutable code/configurations with an immutable incident record.
**Why:** If a runbook is updated or deleted months later, viewing the historical incident must display the exact runbook the operator saw during the incident.

### Pattern 3: Safe Audited Dispatch
**What:** The UI calls `Parapet.Operator.execute_runbook_step/3`. This function ensures the runbook module exists (`String.to_existing_atom`), wraps the callback execution in a transaction, and strictly captures the inputs and success status into a `ToolAudit`.

### Anti-Patterns to Avoid
- **Anti-pattern:** Resolving the runbook step dynamically by module name on the fly during UI render. If the module changes, old incidents break.
- **Anti-pattern:** Using `String.to_atom` on input from the UI or Database. Always use `String.to_existing_atom` to prevent atom exhaustion attacks.
- **Anti-pattern:** Calling mitigation functions directly from LiveView without going through `Parapet.Operator`. This bypasses the Evidence spine and violates D-17 - D-19.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Runbook Storage | Custom relational tables for steps | Ecto `:map` column (`runbook_data`) | Runbook steps are a bounded list and heavily tied to the incident lifecycle. A document-style JSONB column avoids complex joins and perfectly solves the snapshotting requirement. |
| Secure code execution | Ad-hoc `apply` | `Parapet.Operator.execute_runbook_step` | Execution must be wrapped with strict auditing (Actor, Reason, Correlation) and stored in `ToolAudit`. |

## Common Pitfalls

### Pitfall 1: Breaking Historical Execution
**What goes wrong:** A step is renamed or deleted from the runbook module, but the historical incident UI still shows the step (from the snapshot) with a clickable "Execute" button. When clicked, it crashes because the function no longer exists.
**Why it happens:** Snapshot preserves data, but the backend code changes.
**How to avoid:** Catch `UndefinedFunctionError` dynamically or use `function_exported?/3` in `execute_runbook_step` before applying, returning a graceful error like `{:error, :step_no_longer_exists}`. Disable mitigation execution for resolved incidents.

### Pitfall 2: Long-Running Mitigations Blocking UI
**What goes wrong:** A mitigation takes 15 seconds to execute. The LiveView process blocks, and the UI becomes unresponsive.
**Why it happens:** Server-side mitigations run synchronously in the `handle_event` callback.
**How to avoid:** While async `Task` processing is a heavy lift for this phase, document that mitigation callbacks are expected to return relatively quickly. For future phases, asynchronous mitigation dispatch can be explored.

## Code Examples

### 1. Parapet.Runbook Module (Host App Example)
```elixir
defmodule MyApp.Runbooks.DatabaseFailover do
  use Parapet.Runbook

  title "Database Pool Failover"
  description "Run this when Ecto connection pool maxes out."

  step :restart_pool,
    label: "Restart DB Pool",
    description: "Kills all Ecto connections and restarts the pool.",
    type: :mitigation

  step :notify_data_team,
    label: "Notify Data Team",
    description: "Ping the data engineering team in Slack.",
    type: :manual

  def execute_mitigation(:restart_pool, _incident) do
    # Application specific mitigation logic
    {:ok, %{pool_restarted: true}}
  end
end
```

### 2. Parapet.Runbook (Library Implementation)
```elixir
defmodule Parapet.Runbook do
  defmacro __using__(_opts) do
    quote do
      import Parapet.Runbook
      Module.register_attribute(__MODULE__, :steps, accumulate: true)
      @before_compile Parapet.Runbook
      
      # Default empty fallback
      def execute_mitigation(_step, _incident), do: {:error, :not_implemented}
      defoverridable execute_mitigation: 2
    end
  end

  defmacro step(id, opts) do
    quote do
      @steps %{
        id: unquote(id),
        label: unquote(opts)[:label],
        description: unquote(opts)[:description],
        type: unquote(opts)[:type]
      }
    end
  end

  defmacro title(title), do: quote do: @title unquote(title)
  defmacro description(desc), do: quote do: @description unquote(desc)

  defmacro __before_compile__(env) do
    steps = Module.get_attribute(env.module, :steps) |> Enum.reverse()
    title = Module.get_attribute(env.module, :title, "Runbook")
    desc = Module.get_attribute(env.module, :description, "")
    
    quote do
      def __runbook_schema__() do
        %{
          module: to_string(__MODULE__),
          title: unquote(title),
          description: unquote(desc),
          steps: unquote(Macro.escape(steps))
        }
      end
    end
  end
end
```

### 3. Audited Execution in Operator
```elixir
# In Parapet.Operator
def execute_runbook_step(%Incident{} = incident, step_id, %ActionPayload{} = payload) do
  with true <- valid_payload?(payload),
       %{"module" => mod_string} when is_binary(mod_string) <- incident.runbook_data,
       {:module, module} <- ensure_module(mod_string),
       step_atom <- String.to_existing_atom(step_id),
       true <- function_exported?(module, :execute_mitigation, 2) do
       
       # Execute the user's mitigation code safely
       result = apply(module, :execute_mitigation, [step_atom, incident])
       
       # Build Audit and Timeline records
       timeline_attrs = %{
         type: "runbook_mitigation",
         payload: %{"step_id" => step_id, "result" => inspect(result)}
       }
       audit_attrs = build_audit("runbook_mitigation:#{step_id}", payload, result)
       
       Evidence.run_operator_command(
         incident_changeset: Ecto.Changeset.change(incident), # no structural changes to incident
         timeline_attrs: timeline_attrs,
         audit_attrs: audit_attrs
       )
  else
    false -> {:error, :invalid_payload}
    false -> {:error, :step_no_longer_exists}
    error -> {:error, error}
  end
end

defp ensure_module(mod_string) do
  try do
    {:module, String.to_existing_atom(mod_string)}
  rescue
    ArgumentError -> {:error, :invalid_module}
  end
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUNBOOK-01 | Runbook DSL produces schema | unit | `mix test test/parapet/runbook_test.exs` | ❌ Wave 0 |
| RUNBOOK-02 | Incident saves runbook snapshot | integration | `mix test test/parapet/spine/alert_processor_test.exs` | ✅ |
| RUNBOOK-03 | UI displays runbook viewer | unit | `mix test test/parapet/operator_ui_compile_out_test.exs` | ✅ |
| RUNBOOK-04 | Audited mitigation execution | unit | `mix test test/parapet/operator_test.exs` | ✅ |

### Wave 0 Gaps
- [ ] `test/parapet/runbook_test.exs` — covers RUNBOOK-01 DSL validation.
- [ ] `priv/repo/migrations/*_add_runbook_data_to_incidents.exs` — Ecto migration to add `:map` field.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Relies on host app (Doctor verifies UI mounting) |
| V3 Session Management | no | Relies on host app |
| V4 Access Control | yes | Runbook mutations enforce audited `ActionPayload` constraints |
| V5 Input Validation | yes | Strict use of `String.to_existing_atom` and `function_exported?` |

### Known Threat Patterns for Elixir

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom Exhaustion via DB Data | Denial of Service | Use `String.to_existing_atom` when loading module names or step IDs dynamically |
| Arbitrary Code Execution | Tampering / Spoofing | Validate `module` matches `incident.runbook_data["module"]` and check `function_exported?` before `apply/3` |

## Sources

### Primary (HIGH confidence)
- Assessed locally against Parapet evidence-first principles and existing codebase (`docs/operator-ui.md`, `lib/parapet/operator.ex`).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows Elixir best practices (Macros) and existing Ecto schemas.
- Architecture: HIGH - Fits tightly into `Parapet.Operator` and `Evidence` immutable boundaries.
- Pitfalls: HIGH - Addressed known Elixir dynamic dispatch constraints (atom exhaustion).

**Research date:** $(date +"%Y-%m-%d")
**Valid until:** 30 days
