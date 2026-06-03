# Phase 3: Circuit Breakers & Flap Protection - Pattern Map

**Mapped:** 2024-05-19
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/automation/circuit_breaker.ex` | component/service | query-evaluation | `lib/parapet/evidence/retrospective.ex` | role-match |
| `lib/parapet/automation/executor.ex` | worker | event-driven | `lib/parapet/escalation/worker.ex` | exact |
| `test/parapet/automation/circuit_breaker_test.exs` | test | query-evaluation | `test/parapet/automation/executor_test.exs` | role-match |

## Pattern Assignments

### `lib/parapet/automation/circuit_breaker.ex` (component, query-evaluation)

**Analog:** `lib/parapet/evidence/retrospective.ex`

**Imports and Query Pattern** (lines 1-18):
```elixir
defmodule Parapet.Evidence.Retrospective do
  alias Parapet.Spine.Incident
  alias Parapet.Evidence

  def generate_markdown(%Incident{} = incident) do
    import Ecto.Query

    entries =
      Evidence.repo().all(
        from(t in Parapet.Spine.TimelineEntry,
          where: t.incident_id == ^incident.id,
          order_by: [asc: t.inserted_at]
        )
      )
# ...
```
*Note: The circuit breaker should query `Parapet.Spine.ToolAudit` similarly to check execution counts within the window based on `tool_name` or runbook step identifier.*

**Config Pattern**
*Analog: `lib/parapet/escalation/worker.ex` (lines 18-24)*
```elixir
        policy_config = Application.get_env(:parapet, :escalation_policy)

        if policy_config do
          {policy_module, opts} =
            case policy_config do
              {mod, config_opts} -> {mod, config_opts}
              mod when is_atom(mod) -> {mod, []}
            end
```
*Note: Read `max_executions` and `within` window from `Application.get_env(:parapet, :automation)`.*

---

### `lib/parapet/automation/executor.ex` (worker, event-driven)

**Analog:** `lib/parapet/escalation/worker.ex`

**Short-circuit Pattern** (lines 10-15):
```elixir
      %{state: state} when state in ["investigating", "resolved"] ->
        Parapet.Evidence.append_timeline(incident_id, %{
          type: "escalation_short_circuited",
          payload: %{"reason" => "already_#{state}"}
        })

        {:discard, "Short-circuited (already #{state})"}
```
*Note: The executor should short-circuit and emit a discard or error if `Parapet.Automation.CircuitBreaker.allow?/2` returns false, appending a timeline entry for the tripped circuit.*

**Escalation Trigger Pattern**
*Analog: `lib/parapet/evidence.ex` (lines 60-65)*
```elixir
  defp maybe_enqueue_escalation(multi) do
    if Code.ensure_loaded?(Oban) and Application.get_env(:parapet, :escalation_policy) do
      Ecto.Multi.insert(multi, :escalation_job, fn %{incident: incident} ->
        Parapet.Escalation.Worker.new(%{"incident_id" => incident.id})
      end)
    else
      multi
    end
  end
```
*Note: If the automation is blocked/tripped, the executor should immediately enqueue an escalation via `Parapet.Escalation.Worker.new(...) |> Oban.insert!()` so a human can intervene.*

---

### `test/parapet/automation/circuit_breaker_test.exs` (test, query-evaluation)

**Analog:** `test/parapet/automation/executor_test.exs`

**Mock Repo Pattern** (lines 6-39):
```elixir
  defmodule DummyRepo do
    def get(Incident, "not-found"), do: nil
    def get(Incident, id) do
      %Incident{
        id: id,
        correlation_key: "corr_1",
        runbook_data: %{"module" => "Elixir.Parapet.Automation.ExecutorTest.MockRunbook"}
      }
    end
```
*Note: The test will need to implement `all(query)` in the `DummyRepo` module to mock returning varying numbers of `ToolAudit` records to test the boundary of `max_executions`.*

## Shared Patterns

### Identity / Actor Stamping
**Source:** `lib/parapet/automation/executor.ex`
**Apply to:** Timeline entries for short-circuited automations
```elixir
        payload = %ActionPayload{
          actor: "system:automation:executor",
          action_type: :execute_mitigation,
          reason: "Automated runbook mitigation triggered via alert.",
          correlation_id: incident.correlation_key,
          idempotency_key: "auto_exec_#{incident_id}_#{step_id}"
        }
```

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | Found matching patterns for querying and escalating. |

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`, `test/parapet/**/*.exs`
**Files scanned:** 14
**Pattern extraction date:** 2024-05-19
