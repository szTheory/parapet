defmodule Parapet.Metrics.Accrue do
  @moduledoc """
  Prometheus metric definitions for Accrue.
  """
  import Telemetry.Metrics

  def setup do
    :ok
  end

  def metrics do
    [
      counter("parapet.journey.billing.checkout.count", event_name: [:parapet, :journey, :billing, :checkout], tags: [:outcome, :plan]),
      distribution("parapet.journey.billing.webhook.duration", event_name: [:parapet, :journey, :billing, :webhook], tags: [:outcome, :event_type], measurement: :duration)
    ]
  end
end
