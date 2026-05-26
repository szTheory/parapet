defmodule Parapet.Metrics.PrometheusFormatter do
  @moduledoc """
  A custom formatter that wraps standard Prometheus output and injects
  OpenMetrics exemplars for trace_ids from the ExemplarStore.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  alias Parapet.Metrics.ExemplarStore

  def scrape do
    if Code.ensure_loaded?(:telemetry_metrics_prometheus_core) do
      base_text = apply(:telemetry_metrics_prometheus_core, :scrape, [])
      process(base_text)
    else
      ""
    end
  end

  def process(text) do
    text
    |> String.split("\n")
    |> Enum.map(&process_line/1)
    |> Enum.join("\n")
    |> String.trim_trailing()
  end

  defp process_line(line) do
    line = String.trim(line)

    if String.starts_with?(line, "#") or line == "" do
      line
    else
      case parse_metric_and_tags(line) do
        {metric_name, tags} ->
          case ExemplarStore.get_trace(metric_name, tags) do
            nil -> line
            trace_id -> "#{line} # {trace_id=\"#{trace_id}\"}"
          end

        nil ->
          line
      end
    end
  end

  defp parse_metric_and_tags(line) do
    case String.split(line, " ", parts: 2) do
      [metric_part, _rest] ->
        case String.split(metric_part, "{", parts: 2) do
          [name_part, labels_part] ->
            labels_str = String.trim_trailing(labels_part, "}")
            base_name = strip_suffix(name_part)
            {base_name, parse_labels(labels_str)}

          [name_part] ->
            base_name = strip_suffix(name_part)
            {base_name, %{}}
        end

      _ ->
        nil
    end
  end

  defp strip_suffix(name) do
    name
    |> String.replace_suffix("_bucket", "")
    |> String.replace_suffix("_count", "")
    |> String.replace_suffix("_sum", "")
  end

  defp parse_labels(""), do: %{}

  defp parse_labels(labels_str) do
    labels_str
    |> String.split(",")
    |> Enum.reduce(%{}, fn part, acc ->
      case String.split(part, "=", parts: 2) do
        [k, v] ->
          unquoted_v = String.trim(v, "\"")
          Map.put(acc, String.to_atom(k), unquoted_v)

        _ ->
          acc
      end
    end)
    |> Map.delete(:le)
  end
end
