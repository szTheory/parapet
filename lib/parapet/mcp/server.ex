defmodule Parapet.MCP.Server do
  @moduledoc """
  Core MCP server tool execution and routing.
  Provides a controlled, read-only interface for external AI agents to investigate incidents safely.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  alias Parapet.Spine.Incident
  alias Parapet.Spine.TimelineEntry
  alias Parapet.Evidence

  import Ecto.Query, only: [from: 2]

  @doc """
  Executes a read-only tool based on its name and arguments.
  """
  def execute_tool("list_incidents", _args) do
    repo = Evidence.repo()

    query =
      from(i in Incident,
        where: i.state == "open"
      )

    {:ok, repo.all(query)}
  end

  def execute_tool("get_incident_timeline", %{"correlation_key" => correlation_key}) do
    repo = Evidence.repo()

    query =
      from(t in TimelineEntry,
        join: i in Incident,
        on: t.incident_id == i.id,
        where: i.correlation_key == ^correlation_key
      )

    {:ok, repo.all(query)}
  end

  def execute_tool("read_runbook", %{"alertname" => alertname}) do
    slo = Enum.find(Parapet.SLO.all(), fn s -> to_string(s.name) == alertname end)

    case slo do
      %{runbook: runbook} when not is_nil(runbook) ->
        module = get_runbook_module(runbook)

        if module && Code.ensure_loaded?(module) &&
             function_exported?(module, :__runbook_schema__, 0) do
          {:ok, apply(module, :__runbook_schema__, [])}
        else
          {:error, :not_found}
        end

      _ ->
        {:error, :not_found}
    end
  end

  def execute_tool("get_slo_burn_rates", %{"name" => name}) do
    prometheus_client().get_slo_burn_rate(name)
  end

  def execute_tool(_tool_name, _args) do
    {:error, :unknown_tool}
  end

  defp get_runbook_module(runbook) when is_atom(runbook), do: runbook

  defp get_runbook_module(runbook) when is_binary(runbook) do
    try do
      String.to_existing_atom(runbook)
    rescue
      ArgumentError -> nil
    end
  end

  defp get_runbook_module(_), do: nil

  defp prometheus_client do
    Application.get_env(:parapet, :prometheus_client, Parapet.MCP.PrometheusClient)
  end
end
