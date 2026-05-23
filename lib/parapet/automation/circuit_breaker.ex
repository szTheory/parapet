defmodule Parapet.Automation.CircuitBreaker do
  @moduledoc """
  Provides flap protection by short-circuiting automated runbook execution
  if it loops excessively.
  """

  import Ecto.Query

  alias Parapet.Spine.{TimelineEntry, ToolAudit}
  alias Parapet.Evidence

  @doc """
  Checks if a given step for an incident is allowed to execute based on
  historical tool audit records within the configured time window.
  """
  def allow?(incident_id, step_id) do
    case gate(Evidence.repo(), incident_id, step_id) do
      :ok -> true
      {:short_circuit, _reason} -> false
    end
  end

  def gate(repo, incident_id, step_id, opts \\ []) do
    max_executions = opts |> config_value(:max_executions, 3)

    if execution_count(repo, incident_id, step_id, opts) < max_executions do
      :ok
    else
      {:short_circuit, "circuit_breaker_tripped"}
    end
  end

  def execution_count(repo, incident_id, step_id, opts \\ []) do
    query = execution_count_query(incident_id, step_id, opts)
    repo.aggregate(query, :count, :id)
  end

  def execution_count_query(incident_id, step_id, opts \\ []) do
    cutoff =
      opts
      |> config_value(:within, 3600)
      |> then(&DateTime.add(DateTime.utc_now(), -&1, :second))

    expected_idempotency_key = "auto_exec_#{incident_id}_#{step_id}"

    from(a in ToolAudit,
      join: t in TimelineEntry,
      on: a.timeline_entry_id == t.id,
      where: t.incident_id == ^incident_id,
      where: a.inserted_at >= ^cutoff,
      where:
        fragment("?->>'step_id' = ?", t.payload, ^to_string(step_id)) or
          fragment("?->>'idempotency_key' = ?", t.payload, ^expected_idempotency_key)
    )
  end

  defp config_value(opts, key, default) do
    Keyword.get(opts, key, Keyword.get(Application.get_env(:parapet, :automation, []), key, default))
  end
end
