defmodule Parapet.Metrics.Rulestead do
  use Parapet.Metrics.Validator
  @moduledoc """
  Prometheus metric definitions for Rulestead events.
  """

  def metrics do
    import Telemetry.Metrics
    
    [
      counter("parapet_rulestead_flag_change_total",
        event_name: [:parapet, :rulestead, :flag_change],
        tags: [:flag_name, :ruleset],
        description: "The total number of Rulestead flag changes"
      )
    ]
  end
end
