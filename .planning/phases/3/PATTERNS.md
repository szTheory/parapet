# Phase 3: Parapet MCP Server - Pattern Map

**Mapped:** 2024-05-16
**Files analyzed:** 2 (new/modified)
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/plug/mcp.ex` | controller | request-response | `lib/parapet/plug/webhook.ex` | exact |
| `lib/parapet/mcp/server.ex` | service | CRUD (Read-only) | `lib/parapet/spine/alert_processor.ex` | role-match |

## Pattern Assignments

### `lib/parapet/plug/mcp.ex` (controller, request-response)

**Analog:** `lib/parapet/plug/webhook.ex`

**Plug behaviour and Imports pattern** (lines 1-8):
```elixir
defmodule Parapet.Plug.Webhook do
  @moduledoc """
  A Plug to receive webhooks from Alertmanager and route them to the AlertProcessor.
  """

  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts
```

**Core Request Handling (POST) pattern** (lines 12-20):
```elixir
  @impl true
  def call(%{method: "POST"} = conn, _opts) do
    payload = conn.body_params || %{}
    Parapet.Spine.AlertProcessor.process_batch(payload)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(202, Jason.encode!(%{"status" => "accepted"}))
  end
```

**Error Handling (Method Not Allowed) pattern** (lines 22-26):
```elixir
  @impl true
  def call(conn, _opts) do
    conn
    |> send_resp(405, "")
  end
```

---

### `lib/parapet/mcp/server.ex` (service, CRUD Read-only)

**Analog:** `lib/parapet/spine/alert_processor.ex`

**Ecto Query Imports pattern** (lines 6-10):
```elixir
  alias Parapet.Spine.Incident
  alias Parapet.Spine.TimelineEntry
  alias Parapet.Evidence

  import Ecto.Query, only: [from: 2]
```

**Database Query (Read) pattern** (lines 78-83):
```elixir
    repo = Evidence.repo()

    query =
      from(i in Incident, where: i.correlation_key == ^correlation_key and i.state == "open")

    case repo.all(query) do
      [incident | _] ->
```

**Runbook Fetching & Processing pattern** (lines 52-60):
```elixir
    slo = Enum.find(Parapet.SLO.all(), fn s -> to_string(s.name) == alertname end)

    case slo do
      %{runbook: runbook} when not is_nil(runbook) ->
        module = get_runbook_module(runbook)

        if module && Code.ensure_loaded?(module) &&
             function_exported?(module, :__runbook_schema__, 0) do
          # Example of fetching runbook schema details
          apply(module, :__runbook_schema__, [])
```

## Shared Patterns

### Safely Loading Modules / Runbooks
**Source:** `lib/parapet/spine/alert_processor.ex` (lines 71-76)
**Apply to:** `lib/parapet/mcp/server.ex` for safely resolving string runbook references to module atoms during MCP queries.
```elixir
  defp get_runbook_module(runbook) when is_binary(runbook) do
    try do
      String.to_existing_atom(runbook)
    rescue
      ArgumentError -> nil
    end
  end
```

### Retrieving Global SLO Data
**Source:** `lib/parapet/slo.ex` (lines 48-56)
**Apply to:** `lib/parapet/mcp/server.ex` for retrieving SLO details and evaluating burn rates as required by MCP-03.
```elixir
  def all do
    legacy_slos = Application.get_env(:parapet, :slos, [])
    
    provider_slos =
      Application.get_env(:parapet, :providers, [])
      |> Enum.flat_map(fn provider -> provider.slos() end)
      |> Enum.map(&Parapet.SLO.Resolvable.to_slo/1)

    legacy_slos ++ provider_slos
  end
```

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| -    | -    | -         | All components have an existing analog. |

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`
**Files scanned:** 10+
**Pattern extraction date:** 2024-05-16
