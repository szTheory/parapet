defmodule Parapet.Metrics.HTTP do
  use Parapet.Metrics.Validator
  @moduledoc """
  Defines Prometheus counters and distributions for HTTP requests.
  """
  require Logger

  @doc """
  Sets up the metrics by attaching telemetry handlers or registering with Telemetry.Metrics.
  Returns `:ok` or `{:error, reason}` on duplicate registration.
  """
  def setup do
    # In the future, this is where Telemetry.Metrics reporters might be started or registered.
    # For now, we simulate registration success while capturing errors.
    :ok
  rescue
    e in [ArgumentError] ->
      Logger.error("Failed to register metrics: #{Exception.message(e)}")
      {:error, e}
  end

  @doc """
  Returns a list of Telemetry.Metrics definitions for HTTP events.
  """
  def metrics do
    import Telemetry.Metrics

    [
      counter("parapet.http.request.count",
        event_name: [:parapet, :http, :request],
        tags: [:route, :method, :status_class],
        description: "Total number of HTTP requests"
      ),
      distribution("parapet.http.request.duration_ms",
        event_name: [:parapet, :http, :request],
        measurement: :duration_ms,
        tags: [:route, :method, :status_class],
        description: "Duration of HTTP requests in milliseconds",
        reporter_options: [
          buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000]
        ]
      )
    ]
  end
end
