defmodule Parapet.Metrics.AsyncDelivery do
  @moduledoc """
  Shared Telemetry.Metrics catalog and PromQL selector helpers for Phase 5
  async and delivery reliability slices.
  """

  import Telemetry.Metrics

  alias Parapet.Internal.LabelPolicy

  @counter_metric_names %{
    outbound: "parapet_delivery_outbound_total",
    provider_feedback: "parapet_delivery_provider_feedback_total",
    webhook_ingest: "parapet_delivery_webhook_ingest_total",
    stage: "parapet_async_stage_total",
    backlog: "parapet_async_backlog_total",
    callback: "parapet_async_callback_total"
  }

  @distribution_metric_names %{
    outbound: "parapet_delivery_outbound_duration_seconds",
    provider_feedback: "parapet_delivery_provider_feedback_duration_seconds",
    webhook_ingest: "parapet_delivery_webhook_ingest_delay_seconds",
    stage: "parapet_async_stage_duration_seconds",
    backlog: "parapet_async_backlog_delay_seconds",
    callback: "parapet_async_callback_delay_seconds"
  }

  @counter_tags %{
    outbound: [:integration, :provider, :channel, :outcome, :fault_plane],
    provider_feedback: [
      :integration,
      :provider,
      :channel,
      :outcome,
      :failure_class,
      :fault_plane
    ],
    webhook_ingest: [
      :integration,
      :provider,
      :channel,
      :outcome,
      :failure_class,
      :delay_bucket,
      :fault_plane
    ],
    stage: [
      :integration,
      :provider,
      :queue,
      :pipeline_stage,
      :outcome,
      :retry_state,
      :fault_plane
    ],
    backlog: [:integration, :provider, :queue, :outcome, :delay_bucket, :fault_plane],
    callback: [
      :integration,
      :provider,
      :queue,
      :pipeline_stage,
      :outcome,
      :delay_bucket,
      :fault_plane
    ]
  }

  @distribution_tags %{
    outbound: [:integration, :provider, :channel, :outcome, :fault_plane],
    provider_feedback: [
      :integration,
      :provider,
      :channel,
      :outcome,
      :failure_class,
      :fault_plane
    ],
    webhook_ingest: [:integration, :provider, :channel, :fault_plane],
    stage: [:integration, :provider, :queue, :pipeline_stage, :outcome, :retry_state, :fault_plane],
    backlog: [:integration, :provider, :queue, :fault_plane],
    callback: [:integration, :provider, :queue, :pipeline_stage, :fault_plane]
  }

  @delay_buckets [1, 5, 30, 60, 300, 1800, 3600]

  def metrics do
    Enum.flat_map(@counter_metric_names, fn {family, metric_name} ->
      [build_counter_metric(family, metric_name), build_distribution_metric(family)]
    end)
  end

  def metric_name(family, :total), do: Map.fetch!(@counter_metric_names, family)
  def metric_name(family, :duration), do: Map.fetch!(@distribution_metric_names, family)
  def metric_name(family, :delay), do: Map.fetch!(@distribution_metric_names, family)

  def tag_keys(family, :total), do: Map.fetch!(@counter_tags, family)
  def tag_keys(family, :duration), do: Map.fetch!(@distribution_tags, family)
  def tag_keys(family, :delay), do: Map.fetch!(@distribution_tags, family)

  def selector(family_or_metric, matchers \\ [], metric_kind \\ :total)

  def selector(family, matchers, metric_kind) when is_atom(family) do
    render_selector(metric_name(family, metric_kind), matchers)
  end

  def selector(metric_name, matchers, _metric_kind) when is_binary(metric_name) do
    render_selector(metric_name, matchers)
  end

  defp render_selector(metric_name, matchers) do
    normalized =
      matchers
      |> Enum.into(%{})
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Enum.sort_by(fn {key, _value} -> to_string(key) end)

    case normalized do
      [] ->
        metric_name

      _ ->
        rendered =
          normalized
          |> Enum.map_join(", ", fn {key, value} -> "#{key}#{operator(value)}#{render_value(value)}" end)

        "#{metric_name}{#{rendered}}"
    end
  end

  defp build_counter_metric(family, metric_name) do
    tags = tag_keys(family, :total)
    LabelPolicy.assert_family_keys!(family, tags)

    counter(metric_name,
      event_name: event_name(family),
      tags: tags,
      description: counter_description(family)
    )
  end

  defp build_distribution_metric(family) do
    tags = tag_keys(family, distribution_kind(family))
    LabelPolicy.assert_family_keys!(family, tags)

    distribution(metric_name(family, distribution_kind(family)),
      event_name: event_name(family),
      measurement: measurement_for(family),
      tags: tags,
      reporter_options: [buckets: @delay_buckets],
      description: distribution_description(family)
    )
  end

  defp event_name(family) when family in [:outbound, :provider_feedback, :webhook_ingest] do
    [:parapet, :delivery, family]
  end

  defp event_name(family), do: [:parapet, :async, family]

  defp distribution_kind(family) when family in [:webhook_ingest, :backlog, :callback], do: :delay
  defp distribution_kind(_family), do: :duration

  defp measurement_for(family) when family in [:webhook_ingest, :backlog, :callback] do
    fn measurements ->
      measurements
      |> Map.get(:delay_ms, 0)
      |> Kernel./(1000)
    end
  end

  defp measurement_for(_family) do
    fn measurements ->
      measurements
      |> Map.get(:duration_ms, 0)
      |> Kernel./(1000)
    end
  end

  defp counter_description(:outbound), do: "Total normalized outbound delivery attempts"
  defp counter_description(:provider_feedback), do: "Total normalized provider feedback events"
  defp counter_description(:webhook_ingest), do: "Total normalized webhook ingest events"
  defp counter_description(:stage), do: "Total normalized async stage events"
  defp counter_description(:backlog), do: "Total normalized async backlog delay events"
  defp counter_description(:callback), do: "Total normalized async callback delay events"

  defp distribution_description(:outbound), do: "Duration of outbound delivery attempts in seconds"

  defp distribution_description(:provider_feedback),
    do: "Duration of provider feedback handling in seconds"

  defp distribution_description(:webhook_ingest),
    do: "Observed webhook ingest delay in seconds"

  defp distribution_description(:stage), do: "Async stage duration in seconds"
  defp distribution_description(:backlog), do: "Async backlog delay in seconds"
  defp distribution_description(:callback), do: "Async callback delay in seconds"

  defp operator(values) when is_list(values), do: "=~"
  defp operator(_value), do: "="

  defp render_value(values) when is_list(values) do
    quoted =
      values
      |> Enum.map(&render_scalar/1)
      |> Enum.join("|")

    ~s{"#{quoted}"}
  end

  defp render_value(value), do: ~s{"#{render_scalar(value)}"}

  defp render_scalar(value) when is_atom(value), do: Atom.to_string(value)
  defp render_scalar(value), do: to_string(value)
end
