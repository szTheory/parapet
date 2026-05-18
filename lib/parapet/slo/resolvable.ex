defprotocol Parapet.SLO.Resolvable do
  @moduledoc """
  Protocol to transform provider structs to `Parapet.SLO.t()`.
  """

  @fallback_to_any true

  @spec to_slo(t) :: Parapet.SLO.t()
  def to_slo(struct)
end

defimpl Parapet.SLO.Resolvable, for: Parapet.SLO do
  def to_slo(slo), do: slo
end

defimpl Parapet.SLO.Resolvable, for: Parapet.SLO.SliceSpec do
  alias Parapet.Metrics.AsyncDelivery
  alias Parapet.SLO
  alias Parapet.SLO.SliceSpec

  def to_slo(%SliceSpec{} = spec) do
    total_expr = rate_expr(spec.total_source_metric, spec.total_matchers)

    good_expr =
      case spec.kind do
        :diagnostic ->
          bad_expr = rate_expr(spec.bad_source_metric, spec.bad_matchers)
          "clamp_min(#{total_expr} - #{bad_expr}, 0)"

        _ ->
          rate_expr(spec.good_source_metric, spec.good_matchers)
      end

    objective =
      case spec.objective do
        value when is_number(value) -> value
        _ -> (1 - SliceSpec.threshold(spec)) * 100
      end

    %SLO{
      name: spec.name,
      objective: objective,
      good_events: good_expr,
      total_events: total_expr,
      runbook: spec.runbook
    }
  end

  defp rate_expr(metric_name, matchers) do
    "sum(rate(#{AsyncDelivery.selector(metric_name, matchers)}[window]))"
  end
end

defimpl Parapet.SLO.Resolvable, for: Any do
  def to_slo(struct) do
    raise Protocol.UndefinedError,
      protocol: @protocol,
      value: struct,
      description:
        "Parapet.SLO.Resolvable protocol must always be implemented for custom SLO structs"
  end
end
