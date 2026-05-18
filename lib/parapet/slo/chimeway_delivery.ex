defmodule Parapet.SLO.ChimewayDelivery do
  @moduledoc """
  Built-in Phase 5 delivery slices for Chimeway.
  """

  @behaviour Parapet.SLO.Provider

  alias Parapet.Metrics.AsyncDelivery
  alias Parapet.SLO.SliceSpec

  @impl true
  def slos do
    [
      SliceSpec.new(
        name: :chimeway_provider_acceptance,
        integration: :chimeway,
        kind: :diagnostic,
        bad_source_metric: AsyncDelivery.metric_name(:provider_feedback, :total),
        bad_matchers: [
          integration: :chimeway,
          channel: :notification,
          outcome: :failed,
          fault_plane: :provider
        ],
        total_source_metric: AsyncDelivery.metric_name(:provider_feedback, :total),
        total_matchers: [integration: :chimeway, channel: :notification, fault_plane: :provider],
        threshold: 0.01,
        alert_class: :ticket,
        runbook: "https://parapet.dev/runbooks/chimeway-provider-acceptance",
        group_labels: [:integration, :provider, :channel],
        labels: %{fault_plane: :provider},
        summary: "Chimeway provider acceptance failures are sustained"
      ),
      SliceSpec.new(
        name: :chimeway_callback_confirmation,
        integration: :chimeway,
        kind: :diagnostic,
        bad_source_metric: AsyncDelivery.metric_name(:webhook_ingest, :total),
        bad_matchers: [
          integration: :chimeway,
          channel: :notification,
          outcome: :failed,
          fault_plane: :webhook
        ],
        total_source_metric: AsyncDelivery.metric_name(:webhook_ingest, :total),
        total_matchers: [integration: :chimeway, channel: :notification, fault_plane: :webhook],
        threshold: 0.01,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/chimeway-callback-confirmation",
        group_labels: [:integration, :provider, :channel],
        labels: %{fault_plane: :webhook},
        summary: "Chimeway callback confirmation failures are sustained"
      ),
      SliceSpec.new(
        name: :chimeway_callback_freshness,
        integration: :chimeway,
        kind: :freshness,
        source_metric: AsyncDelivery.metric_name(:webhook_ingest, :total),
        good_matchers: [
          integration: :chimeway,
          channel: :notification,
          delay_bucket: [:subsecond, :under_30s],
          fault_plane: :webhook
        ],
        total_matchers: [integration: :chimeway, channel: :notification, fault_plane: :webhook],
        objective: 99.0,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/chimeway-callback-freshness",
        group_labels: [:integration, :provider, :channel],
        labels: %{fault_plane: :webhook},
        min_total_rate: 0.001,
        summary: "Chimeway callback freshness is stale"
      )
    ]
  end
end
