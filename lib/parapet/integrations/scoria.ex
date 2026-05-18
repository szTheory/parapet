defmodule Parapet.Integrations.Scoria do
  @moduledoc """
  Parapet integration for the Scoria AI library.
  Listens to Scoria telemetry events and translates them into Parapet metrics
  while stripping high-cardinality metadata and creating incidents for severe errors.
  """

  require Logger

  @safe_labels [:model, :provider, :tool_name]

  @doc """
  Attaches telemetry handlers for Scoria events.
  """
  def setup do
    # Attach Phase 1 SRE telemetry
    :telemetry.attach(
      "parapet-scoria-telemetry",
      [:scoria, :sre, :telemetry],
      &__MODULE__.handle_event/4,
      nil
    )

    # Attach AI Config deployments
    :telemetry.attach(
      "parapet-scoria-config-telemetry",
      [:scoria, :config, :deployed],
      &__MODULE__.handle_event/4,
      nil
    )

    # Attach MCP tool exceptions
    :telemetry.attach(
      "parapet-scoria-mcp-telemetry",
      [:scoria, :mcp, :tool, :exception],
      &__MODULE__.handle_event/4,
      nil
    )

    # Attach Phase 4 workflow staleness/expiration/resumed
    :telemetry.attach_many(
      "parapet-scoria-workflow-telemetry",
      [
        [:scoria, :workflow, :stale],
        [:scoria, :workflow, :expired],
        [:scoria, :workflow, :resumed]
      ],
      &__MODULE__.handle_event/4,
      nil
    )

    # Attach Phase 2 AI Eval metrics
    Parapet.Metrics.Scoria.setup()
  end

  @doc """
  Handles Scoria telemetry events, translates them to Parapet metrics,
  and logs incidents for AI tool failures.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}"
      )

      :ok
  end

  defp process_event([:scoria, :sre, :telemetry], measurements, metadata) do
    # Extract only low-cardinality labels
    safe_metadata = Map.take(metadata, @safe_labels)

    # Determine outcome based on :error presence
    has_error? = Map.has_key?(metadata, :error) and not is_nil(metadata.error)
    outcome = if has_error?, do: :failure, else: :success

    parapet_metadata = Map.put(safe_metadata, :outcome, outcome)

    # Emit translated event
    :telemetry.execute(
      [:parapet, :scoria, :metrics],
      measurements,
      parapet_metadata
    )

    # Route errors to Parapet.Evidence.create_incident/1
    if has_error? do
      Parapet.Evidence.create_incident(%{
        title: "Scoria AI Execution Failure: #{Map.get(metadata, :tool_name, "Unknown Tool")}",
        description: "An error occurred during AI execution:\n\n#{inspect(metadata.error)}",
        state: "open",
        severity: "high"
      })
    end

    :ok
  end

  defp process_event([:scoria, :config, :deployed], _measurements, metadata) do
    Parapet.Evidence.create_incident(%{
      title: "AI Config Deployed",
      state: "open",
      runbook_data: %{
        "type" => "config_change",
        "scorer_version" => metadata[:scorer_version],
        "baseline_version" => metadata[:baseline_version],
        "model" => metadata[:model]
      }
    })

    :ok
  end

  defp process_event([:scoria, :mcp, :tool, :exception], measurements, metadata) do
    mapped_reason = map_mcp_failure(metadata[:error])

    :telemetry.execute(
      [:parapet, :scoria, :mcp, :error],
      measurements,
      %{reason: mapped_reason, tool_name: metadata[:tool_name]}
    )

    :ok
  end

  defp process_event([:scoria, :workflow, :stale], measurements, metadata) do
    # Track 1: Low cardinality metrics
    safe_metadata =
      Map.take(metadata, @safe_labels) |> Map.put(:workflow_id, metadata[:workflow_id])

    :telemetry.execute(
      [:parapet, :scoria, :metrics, :stale],
      measurements,
      safe_metadata
    )

    # Track 2: Durable Evidence for Operator UI
    Parapet.Evidence.create_action_item(%{
      integration: "scoria",
      external_id: metadata[:workflow_id],
      title: "Workflow #{metadata[:workflow_id]} is stale"
    })

    :ok
  end

  defp process_event([:scoria, :workflow, :expired], measurements, metadata) do
    safe_metadata =
      Map.take(metadata, @safe_labels) |> Map.put(:workflow_id, metadata[:workflow_id])

    :telemetry.execute(
      [:parapet, :scoria, :metrics, :expired],
      measurements,
      safe_metadata
    )

    :ok
  end

  defp process_event([:scoria, :workflow, :resumed], measurements, metadata) do
    safe_metadata =
      Map.take(metadata, @safe_labels) |> Map.put(:workflow_id, metadata[:workflow_id])

    :telemetry.execute(
      [:parapet, :scoria, :metrics, :resumed],
      measurements,
      safe_metadata
    )

    check_status(metadata[:workflow_id])

    :ok
  end

  # Catch-all
  defp process_event(_event, _measurements, _metadata), do: :ok

  @doc """
  Checks the external Scoria workflow state and conditionally resolves the action item
  if the workflow is no longer paused.
  """
  def check_status(workflow_id) do
    if Code.ensure_loaded?(Scoria.Workflow) do
      state = apply(Scoria.Workflow, :get_state, [workflow_id])

      if state != :paused do
        Parapet.Evidence.resolve_action_item(integration: "scoria", external_id: workflow_id)
      end
    end
  end

  defp map_mcp_failure(%{reason: :timeout}), do: "timeout"
  defp map_mcp_failure(%{reason: :breaker_open}), do: "breaker_open"
  defp map_mcp_failure(%{reason: :access_denied}), do: "access_denied"
  defp map_mcp_failure(_), do: "execution_failed"
end
