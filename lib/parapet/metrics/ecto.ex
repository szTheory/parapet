defmodule Parapet.Metrics.Ecto do
  @moduledoc """
  Defines Prometheus distributions for Ecto queries.
  """
  require Logger

  alias Parapet.Internal.LabelPolicy

  @doc """
  Sets up the Ecto metrics by attaching a telemetry handler.
  Takes the event prefix (e.g., `[:my_app, :repo]`).
  """
  def setup(event_prefix) do
    event_name = event_prefix ++ [:query]

    Parapet.attach(%{
      handler_id: "parapet-ecto-handler",
      event_name: event_name,
      handler_module: __MODULE__,
      function_name: :handle_event
    })

    :ok
  rescue
    e in [ArgumentError] ->
      Logger.error("Failed to register Ecto metrics: #{Exception.message(e)}")
      {:error, e}
  end

  @doc """
  Returns a list of Telemetry.Metrics definitions for Ecto events.
  """
  def metrics do
    import Telemetry.Metrics

    LabelPolicy.assert_safe!([:source])

    [
      distribution("parapet.ecto.query.query_time_ms",
        event_name: [:parapet, :ecto, :query],
        measurement: :query_time_ms,
        tags: [:source],
        description: "Duration of Ecto queries in milliseconds",
        reporter_options: [
          buckets: [1, 5, 10, 25, 50, 100, 250, 500, 1000]
        ]
      ),
      distribution("parapet.ecto.query.queue_time_ms",
        event_name: [:parapet, :ecto, :query],
        measurement: :queue_time_ms,
        tags: [:source],
        description: "Duration of Ecto queue times in milliseconds",
        reporter_options: [
          buckets: [1, 5, 10, 25, 50, 100, 250, 500, 1000]
        ]
      )
    ]
  end

  @doc false
  def handle_event(_event, measurements, metadata, _config) do
    query_time = Map.get(measurements, :query_time)
    queue_time = Map.get(measurements, :queue_time)

    query_time_ms =
      if query_time, do: System.convert_time_unit(query_time, :native, :millisecond), else: 0

    queue_time_ms =
      if queue_time, do: System.convert_time_unit(queue_time, :native, :millisecond), else: 0

    source = Map.get(metadata, :source, "_raw")
    source = if source == nil, do: "_raw", else: source
    source = to_string(source)

    :telemetry.execute(
      [:parapet, :ecto, :query],
      %{query_time_ms: query_time_ms, queue_time_ms: queue_time_ms},
      %{source: source}
    )
  end
end
