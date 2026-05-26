defmodule Parapet.SLO.MailglassDelivery do
  @moduledoc """
  Built-in Phase 5 delivery slices for Mailglass.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @behaviour Parapet.SLO.Provider

  alias Parapet.Metrics.AsyncDelivery
  alias Parapet.SLO.SliceSpec

  @impl true
  def slos do
    [
      SliceSpec.new(
        name: :mailglass_submit_acceptance,
        integration: :mailglass,
        kind: :ratio,
        good_source_metric: AsyncDelivery.metric_name(:provider_feedback, :total),
        good_matchers: [
          integration: :mailglass,
          channel: :email,
          outcome: :provider_accepted,
          fault_plane: :provider
        ],
        total_source_metric: AsyncDelivery.metric_name(:outbound, :total),
        total_matchers: [
          integration: :mailglass,
          channel: :email,
          outcome: :attempted,
          fault_plane: :provider
        ],
        objective: 99.0,
        alert_class: :ticket,
        runbook: "https://parapet.dev/runbooks/mailglass-submit-acceptance",
        group_labels: [:integration, :provider, :channel],
        labels: %{fault_plane: :provider},
        summary: "Mailglass provider acceptance is slipping"
      ),
      SliceSpec.new(
        name: :mailglass_confirmed_delivery,
        integration: :mailglass,
        kind: :ratio,
        good_source_metric: AsyncDelivery.metric_name(:provider_feedback, :total),
        good_matchers: [
          integration: :mailglass,
          channel: :email,
          outcome: :delivered,
          fault_plane: :provider
        ],
        total_source_metric: AsyncDelivery.metric_name(:outbound, :total),
        total_matchers: [
          integration: :mailglass,
          channel: :email,
          outcome: :attempted,
          fault_plane: :provider
        ],
        objective: 99.0,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/mailglass-confirmed-delivery",
        group_labels: [:integration, :provider, :channel],
        labels: %{fault_plane: :provider},
        summary: "Mailglass confirmed delivery is burning budget"
      ),
      SliceSpec.new(
        name: :mailglass_webhook_freshness,
        integration: :mailglass,
        kind: :freshness,
        source_metric: AsyncDelivery.metric_name(:webhook_ingest, :total),
        good_matchers: [
          integration: :mailglass,
          channel: :email,
          delay_bucket: [:subsecond, :under_30s],
          fault_plane: :webhook
        ],
        total_matchers: [integration: :mailglass, channel: :email, fault_plane: :webhook],
        objective: 99.0,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/mailglass-webhook-freshness",
        group_labels: [:integration, :provider, :channel],
        labels: %{fault_plane: :webhook},
        min_total_rate: 0.001,
        summary: "Mailglass webhook freshness is stale"
      ),
      SliceSpec.new(
        name: :mailglass_suppression_drift,
        integration: :mailglass,
        kind: :diagnostic,
        bad_source_metric: AsyncDelivery.metric_name(:provider_feedback, :total),
        bad_matchers: [
          integration: :mailglass,
          channel: :email,
          outcome: :suppressed
        ],
        total_source_metric: AsyncDelivery.metric_name(:outbound, :total),
        total_matchers: [
          integration: :mailglass,
          channel: :email,
          outcome: :attempted,
          fault_plane: :provider
        ],
        threshold: 0.02,
        alert_class: :diagnostic,
        runbook: "https://parapet.dev/runbooks/mailglass-suppression-drift",
        group_labels: [:integration, :provider, :channel],
        labels: %{fault_plane: :suppression},
        summary: "Mailglass suppression drift is elevated"
      )
    ]
  end
end
