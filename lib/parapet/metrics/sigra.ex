defmodule Parapet.Metrics.Sigra do
  @moduledoc """
  Prometheus metric definitions for Sigra.
  """
  import Telemetry.Metrics

  def setup do
    :ok
  end

  def metrics do
    [
      counter("parapet.journey.login.count",
        event_name: [:parapet, :journey, :login],
        tags: [:outcome]
      ),
      counter("parapet.journey.signup.count",
        event_name: [:parapet, :journey, :signup],
        tags: [:outcome, :provider]
      )
    ]
  end
end
