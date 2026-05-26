defmodule Parapet.Metrics.Accrue do
  use Parapet.Metrics.Validator

  @moduledoc """
  Prometheus metric definitions for Accrue.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  import Telemetry.Metrics

  def setup do
    :ok
  end

  def metrics do
    [
      counter("parapet.journey.billing.checkout.count",
        event_name: [:parapet, :journey, :billing, :checkout],
        tags: [:outcome, :plan]
      ),
      distribution("parapet.journey.billing.webhook.duration",
        event_name: [:parapet, :journey, :billing, :webhook],
        tags: [:outcome, :event_type],
        measurement: :duration
      )
    ]
  end
end
