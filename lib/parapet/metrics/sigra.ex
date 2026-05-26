defmodule Parapet.Metrics.Sigra do
  use Parapet.Metrics.Validator

  @moduledoc """
  Prometheus metric definitions for Sigra.

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
