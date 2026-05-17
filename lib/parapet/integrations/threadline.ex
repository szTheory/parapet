defmodule Parapet.Integrations.Threadline do
  @moduledoc """
  Parapet integration for the Threadline audit library.
  Maps audit data between Threadline and Parapet.
  """

  require Logger

  @doc """
  Attaches telemetry handlers for Threadline audit events and Parapet audit events.
  """
  def setup do
    :telemetry.attach(
      "parapet-threadline-audit",
      [:threadline, :audit, :event],
      &__MODULE__.handle_event/4,
      nil
    )

    :telemetry.attach(
      "parapet-audit-to-threadline",
      [:parapet, :audit, :created],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Safely translates Parapet.Spine.ToolAudit or a map to Threadline schema shapes.
  """
  def to_threadline_shape(%Parapet.Spine.ToolAudit{} = audit) do
    %{
      action: audit.tool_name,
      payload: audit.input,
      success: audit.success
    }
  end

  def to_threadline_shape(attrs) when is_map(attrs) do
    %{
      action: Map.get(attrs, :tool_name) || Map.get(attrs, "tool_name"),
      payload: Map.get(attrs, :input) || Map.get(attrs, "input"),
      success: Map.get(attrs, :success, Map.get(attrs, "success", true))
    }
  end

  @doc """
  Handles telemetry events safely.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
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

  defp process_event([:parapet, :audit, :created], _measurements, metadata) do
    if Code.ensure_loaded?(Threadline) do
      audit_attrs = Map.get(metadata, :audit_attrs, %{})
      mapped_attrs = to_threadline_shape(audit_attrs)
      apply(Threadline, :log_audit, [mapped_attrs])
    else
      :ok
    end
  end

  defp process_event(_event, _measurements, _metadata), do: :ok
end
