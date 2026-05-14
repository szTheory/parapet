defmodule Parapet.Metrics.Scoria do
  @moduledoc """
  Defines Prometheus counters and distributions for Scoria evaluation metrics.
  """
  require Logger

  @doc """
  Sets up the metrics by attaching telemetry handlers.
  Returns `:ok` or `{:error, reason}` on duplicate registration.
  """
  def setup do
    :telemetry.attach(
      "parapet-scoria-eval-handler",
      [:scoria, :eval, :completed],
      &__MODULE__.handle_event/4,
      nil
    )
    :ok
  rescue
    e in [ArgumentError] ->
      Logger.error("Failed to register Scoria metrics handler: #{Exception.message(e)}")
      {:error, e}
  end

  @doc false
  def handle_event(_name, measurements, metadata, _config) do
    # Strictly enforce cardinality limit
    sanitized_metadata = Map.take(metadata, [:guardrail, :passed, :model_name])

    :telemetry.execute(
      [:parapet, :scoria, :eval, :completed],
      measurements,
      sanitized_metadata
    )
  end

  @doc """
  Returns a list of Telemetry.Metrics definitions for Scoria events.
  """
  def metrics do
    import Telemetry.Metrics

    [
      counter("scoria_evaluation_total",
        event_name: [:parapet, :scoria, :eval, :completed],
        tags: [:guardrail, :passed, :model_name],
        description: "Total number of Scoria AI evaluations"
      ),
      counter("scoria_mcp_errors_total",
        event_name: [:parapet, :scoria, :mcp, :error],
        tags: [:reason, :tool_name],
        description: "Total number of Scoria MCP tool failures"
      )
    ]
  end
end
