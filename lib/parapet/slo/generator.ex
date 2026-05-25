defmodule Parapet.SLO.Generator do
  @moduledoc """
  Generates provider-first Prometheus recording and alert rules from
  bounded slice specs while retaining legacy `%Parapet.SLO{}` support.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  alias Parapet.SLO
  alias Parapet.SLO.SliceSpec

  @windows ["5m", "30m", "1h", "2h", "6h", "3d"]

  def windows, do: @windows

  def provider_artifacts(windows \\ @windows) do
    build_artifacts(SLO.provider_catalog(), windows)
  end

  def build_artifacts(entries, windows \\ @windows) do
    recording_groups = recording_groups(entries, windows)
    alert_groups = alert_groups(entries)

    %{
      recording_rules: render_template("recording_rules.yml.eex", recording_groups),
      alerts: render_template("alerts.yml.eex", alert_groups),
      rules: render_template("rules.yml.eex", recording_groups ++ alert_groups)
    }
  end

  def recording_groups(entries, windows \\ @windows) do
    Enum.map(entries, &recording_group(&1, windows))
  end

  def alert_groups(entries) do
    Enum.map(entries, &alert_group/1)
  end

  @doc """
  Generates legacy YAML for a single SLO.
  """
  def generate_yaml(%Parapet.SLO{} = slo) do
    slo
    |> recording_group(["5m", "30m", "1h"])
    |> then(fn group -> render_template("recording_rules.yml.eex", [group]) end)
  end

  def yaml_value(value) when is_boolean(value), do: if(value, do: "true", else: "false")
  def yaml_value(value) when is_atom(value), do: value |> Atom.to_string() |> quoted()
  def yaml_value(value) when is_number(value), do: to_string(value)
  def yaml_value(value), do: value |> to_string() |> quoted()

  defp recording_group(%SliceSpec{} = spec, windows) do
    rules =
      Enum.flat_map(windows, fn window ->
        [
          %{
            record: ratio_record_name(spec.name, window),
            expr: ratio_expr(spec, window),
            labels: %{slice: spec.name, integration: spec.integration}
          },
          %{
            record: total_rate_record_name(spec.name, window),
            expr: total_rate_expr(spec, window),
            labels: %{slice: spec.name, integration: spec.integration}
          }
        ]
      end)

    %{name: group_name(spec.name, "recording"), rules: rules}
  end

  defp recording_group(%SLO{} = slo, windows) do
    rules =
      Enum.flat_map(windows, fn window ->
        [
          %{
            record: ratio_record_name(slo.name, window),
            expr: legacy_ratio_expr(slo, window),
            labels: %{slice: slo.name, integration: "legacy"}
          },
          %{
            record: total_rate_record_name(slo.name, window),
            expr: legacy_total_expr(slo, window),
            labels: %{slice: slo.name, integration: "legacy"}
          }
        ]
      end)

    %{name: group_name(slo.name, "recording"), rules: rules}
  end

  defp alert_group(%SliceSpec{} = spec) do
    %{window: window, multiplier: multiplier} = alert_profile(spec)
    threshold = spec |> SliceSpec.threshold() |> Kernel.*(multiplier) |> Float.round(6)

    labels =
      spec.labels
      |> Map.merge(%{
        severity: SliceSpec.severity(spec),
        integration: spec.integration,
        slice: spec.name
      })

    rule = %{
      alert: alert_name(spec),
      expr:
        "#{ratio_record_name(spec.name, window)} > #{threshold} and #{total_rate_record_name(spec.name, window)} > #{spec.min_total_rate}",
      for: spec.for || SliceSpec.default_for(spec),
      keep_firing_for: spec.keep_firing_for || SliceSpec.default_keep_firing_for(spec),
      labels: labels,
      annotations: %{
        summary: spec.summary || default_summary(spec),
        runbook: spec.runbook
      }
    }

    %{name: group_name(spec.name, "alerts"), rules: [rule]}
  end

  defp alert_group(%SLO{} = slo) do
    error_budget = 1 - slo.objective / 100

    rule = %{
      alert: "#{Macro.camelize(to_string(slo.name))}SLOBurnRateWarning",
      expr:
        "#{ratio_record_name(slo.name, "6h")} > #{Float.round(error_budget, 6)} and #{total_rate_record_name(slo.name, "6h")} > 0.01",
      for: "30m",
      keep_firing_for: "15m",
      labels: %{severity: "warning", integration: "legacy", slice: slo.name},
      annotations: %{
        summary: "Legacy SLO #{slo.name} is burning budget",
        runbook: slo.runbook
      }
    }

    %{name: group_name(slo.name, "alerts"), rules: [rule]}
  end

  defp ratio_expr(%SliceSpec{} = spec, window) do
    total_expr = total_rate_expr(spec, window)
    value_expr = value_rate_expr(spec, window)

    case spec.kind do
      :diagnostic -> "#{value_expr} / clamp_min(#{total_expr}, 1)"
      _ -> "1 - (#{value_expr} / clamp_min(#{total_expr}, 1))"
    end
  end

  defp total_rate_expr(%SliceSpec{} = spec, window) do
    aggregate_rate(spec.total_source_metric, spec.total_matchers, spec.group_labels, window)
  end

  defp value_rate_expr(%SliceSpec{} = spec, window) do
    aggregate_rate(SliceSpec.value_metric(spec), SliceSpec.value_matchers(spec), spec.group_labels, window)
  end

  defp aggregate_rate(metric, matchers, labels, window) do
    selector = Parapet.Metrics.AsyncDelivery.selector(metric, matchers)
    "sum by (#{Enum.map_join(labels, ", ", &to_string/1)})(rate(#{selector}[#{window}]))"
  end

  defp legacy_ratio_expr(%SLO{} = slo, window) do
    total_expr = legacy_total_expr(slo, window)
    good_expr = legacy_rate_expr(slo.good_events, window)
    "1 - (#{good_expr} / clamp_min(#{total_expr}, 1))"
  end

  defp legacy_total_expr(%SLO{} = slo, window) do
    legacy_rate_expr(slo.total_events, window)
  end

  defp legacy_rate_expr(query, window) do
    query = sanitize_promql(query)

    if String.contains?(query, "[window]") do
      String.replace(query, "[window]", "[#{window}]")
    else
      "sum(rate(#{query}[#{window}]))"
    end
  end

  defp render_template(template_name, groups) do
    template_path =
      Application.app_dir(:parapet, "priv/templates/parapet.gen.prometheus/#{template_name}")

    EEx.eval_file(template_path, groups: groups, generator: __MODULE__)
  end

  defp group_name(name, suffix), do: "parapet_#{name}_#{suffix}"
  defp ratio_record_name(name, window), do: "parapet:#{name}:error_ratio:#{window}"
  defp total_rate_record_name(name, window), do: "parapet:#{name}:total_rate:#{window}"

  defp alert_name(%SliceSpec{} = spec) do
    "#{Macro.camelize(to_string(spec.name))}#{Macro.camelize(SliceSpec.severity(spec))}"
  end

  defp alert_profile(%SliceSpec{alert_class: :page}), do: %{window: "5m", multiplier: 14.4}
  defp alert_profile(%SliceSpec{alert_class: :ticket}), do: %{window: "30m", multiplier: 6.0}
  defp alert_profile(%SliceSpec{alert_class: :warning}), do: %{window: "6h", multiplier: 1.0}
  defp alert_profile(%SliceSpec{alert_class: :diagnostic}), do: %{window: "30m", multiplier: 1.0}

  defp default_summary(%SliceSpec{} = spec) do
    "#{Macro.camelize(to_string(spec.integration))} #{String.replace(to_string(spec.name), "_", " ")} is outside bounds"
  end

  defp quoted(value) do
    escaped = String.replace(value, "\"", "\\\"")
    ~s("#{escaped}")
  end

  defp sanitize_promql(query) do
    query
    |> String.replace(~r/[\n\r]/, " ")
    |> String.trim()
  end
end
