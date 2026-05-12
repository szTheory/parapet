defmodule Parapet.Integrations.Threadline do
  @moduledoc """
  Parapet integration for the Threadline audit library.
  Maps audit data between Threadline and Parapet.
  """

  require Logger

  @doc """
  Attaches telemetry handlers for Threadline audit events.
  """
  def setup do
    :telemetry.attach(
      "parapet-threadline-audit",
      [:threadline, :audit, :event],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Safely translates Parapet.Spine.ToolAudit to Threadline schema shapes.
  """
  def to_threadline_shape(%Parapet.Spine.ToolAudit{} = audit) do
    %{
      action: audit.tool_name,
      payload: audit.input,
      success: audit.success
    }
  end

  @doc """
  Handles Threadline telemetry events safely and emits Parapet ToolAudit.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}"
      )
  end

  defp process_event([:threadline, :audit, :event], measurements, metadata) do
    attrs = %{
      tool_name: "threadline:#{Map.get(metadata, :action, "unknown")}",
      input: Map.get(metadata, :payload, %{}),
      output: %{},
      success: Map.get(metadata, :success, true),
      duration_ms: Map.get(measurements, :duration_ms)
    }

    Parapet.Evidence.log_tool_audit(attrs)
  end

  defp process_event(_event, _measurements, _metadata), do: :ok
end
