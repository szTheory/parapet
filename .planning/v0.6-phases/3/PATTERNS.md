# Phase 3: Threadline Compliance Sync - Pattern Map

**Mapped:** 2024-05-17
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/audit/writer.ex` | behavior | interface | `lib/parapet/slo/provider.ex` | role-match |
| `lib/parapet/audit/reader.ex` | behavior | interface | `lib/parapet/slo/provider.ex` | role-match |
| `lib/parapet/audit/ecto_writer.ex` | adapter | CRUD | `lib/parapet/evidence.ex` | partial-match |
| `lib/parapet/audit/ecto_reader.ex` | adapter | CRUD | `lib/parapet/evidence.ex` | partial-match |
| `lib/parapet/integrations/threadline.ex` | integration | event-driven | `lib/parapet/integrations/mailglass.ex` | exact |
| `lib/parapet/evidence.ex` | service | CRUD | `lib/parapet/notifier.ex` | role-match |

## Pattern Assignments

### `lib/parapet/audit/writer.ex` & `lib/parapet/audit/reader.ex` (behavior, interface)

**Analog:** `lib/parapet/slo/provider.ex`

**Behavior Pattern** (lines 1-7):
```elixir
defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for providing SLOs to the Parapet system.
  """

  @callback slos() :: [struct()]
end
```
*(Use this structure to define `@callback write/1` and `@callback read/1` for audit behaviors.)*

---

### `lib/parapet/audit/ecto_writer.ex` (adapter, CRUD)

**Analog:** `lib/parapet/evidence.ex`

**Ecto Insert Pattern** (lines 52-57):
```elixir
  @doc """
  Logs a ToolAudit entry.
  """
  def log_tool_audit(attrs \\ %{}) do
    %ToolAudit{}
    |> ToolAudit.changeset(attrs)
    |> repo().insert()
  end
```
*(Extract the direct Ecto insertion logic from `Evidence` into this adapter implementation.)*

---

### `lib/parapet/audit/ecto_reader.ex` (adapter, CRUD)

**Analog:** `lib/parapet/evidence.ex`

**Ecto Query Pattern** (lines 32-35):
```elixir
  def resolve_action_item(id) do
    from(a in ActionItem, where: a.id == ^id)
    |> repo().update_all(set: [state: "resolved"])
  end
```
*(Use Ecto `from` queries to implement read operations for UI timelines.)*

---

### `lib/parapet/integrations/threadline.ex` (integration, event-driven)

**Analog:** `lib/parapet/integrations/mailglass.ex`

**Telemetry Handler Pattern** (lines 16-22):
```elixir
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
      )
  end
```
*(Threadline integration should implement robust telemetry event handlers to bridge the Parapet telemetry events into Threadline.)*

---

### `lib/parapet/evidence.ex` (service, CRUD)

**Analog:** `lib/parapet/probe.ex` & `lib/parapet/notifier.ex`

**Telemetry Execution Pattern** (mailglass.ex lines 24-30):
```elixir
  defp process_event([:mailglass, :delivery, :failure], measurements, _metadata) do
    parapet_metadata = %{outcome: :failure}

    :telemetry.execute(
      [:parapet, :journey, :mail_delivery],
      %{duration: measurements.duration},
      parapet_metadata
    )
  end
```
*(Use `:telemetry.execute` to universally broadcast `[:parapet, :audit, :*]` events in place of hard dependencies.)*

## Shared Patterns

### Configuration-Driven Injection
**Source:** `lib/parapet/notifier.ex`
**Apply to:** `Parapet.Evidence` or audit orchestrator.
```elixir
  def broadcast(incident) do
    notifiers = Application.get_env(:parapet, :notifiers, [])
```
*(Fetch the configured `audit_writer` and `audit_reader` with `Application.get_env/3` allowing fallback to the default Ecto adapters).*

## No Analog Found

None. All required patterns are well-represented in the current Parapet ecosystem.

## Metadata

**Analog search scope:** `lib/parapet/`, `lib/parapet/integrations/`, `lib/parapet/slo/`
**Files scanned:** 6+ detailed
**Pattern extraction date:** 2024-05-17