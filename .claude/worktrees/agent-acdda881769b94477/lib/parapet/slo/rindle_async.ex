defmodule Parapet.SLO.RindleAsync do
  @moduledoc """
  Built-in Phase 5 async reliability slices for Rindle.

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
        name: :rindle_terminal_success,
        integration: :rindle,
        kind: :ratio,
        source_metric: AsyncDelivery.metric_name(:stage, :total),
        good_matchers: [integration: :rindle, outcome: :succeeded, fault_plane: :worker],
        total_matchers: [
          integration: :rindle,
          outcome: [:succeeded, :discarded],
          fault_plane: :worker
        ],
        objective: 99.0,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/rindle-terminal-success",
        group_labels: [:integration, :provider, :queue, :pipeline_stage],
        labels: %{fault_plane: :worker},
        summary: "Rindle is discarding user-harming work"
      ),
      SliceSpec.new(
        name: :rindle_queue_freshness,
        integration: :rindle,
        kind: :freshness,
        source_metric: AsyncDelivery.metric_name(:backlog, :total),
        good_matchers: [
          integration: :rindle,
          delay_bucket: [:subsecond, :under_30s, :under_5m],
          fault_plane: :backlog
        ],
        total_matchers: [integration: :rindle, fault_plane: :backlog],
        objective: 99.0,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/rindle-queue-freshness",
        group_labels: [:integration, :provider, :queue],
        labels: %{fault_plane: :backlog},
        min_total_rate: 0.001,
        summary: "Rindle queue freshness is degraded"
      ),
      SliceSpec.new(
        name: :rindle_callback_freshness,
        integration: :rindle,
        kind: :freshness,
        source_metric: AsyncDelivery.metric_name(:callback, :total),
        good_matchers: [
          integration: :rindle,
          delay_bucket: [:subsecond, :under_30s, :under_5m],
          fault_plane: :webhook
        ],
        total_matchers: [integration: :rindle, fault_plane: :webhook],
        objective: 99.0,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/rindle-callback-freshness",
        group_labels: [:integration, :provider, :queue, :pipeline_stage],
        labels: %{fault_plane: :webhook},
        min_total_rate: 0.001,
        summary: "Rindle callback freshness is degraded"
      ),
      SliceSpec.new(
        name: :rindle_long_running_stage,
        integration: :rindle,
        kind: :diagnostic,
        bad_source_metric: AsyncDelivery.metric_name(:stage, :total),
        bad_matchers: [integration: :rindle, outcome: :retryable_failed, fault_plane: :worker],
        total_source_metric: AsyncDelivery.metric_name(:stage, :total),
        total_matchers: [integration: :rindle, fault_plane: :worker],
        threshold: 0.05,
        alert_class: :diagnostic,
        runbook: "https://parapet.dev/runbooks/rindle-long-running-stage",
        group_labels: [:integration, :provider, :queue, :pipeline_stage],
        labels: %{fault_plane: :worker},
        summary: "Rindle retry-heavy stages are drifting"
      ),
      SliceSpec.new(
        name: :rindle_funnel_regression,
        integration: :rindle,
        kind: :diagnostic,
        bad_source_metric: AsyncDelivery.metric_name(:stage, :total),
        bad_matchers: [
          integration: :rindle,
          outcome: [:retryable_failed, :discarded],
          fault_plane: :worker
        ],
        total_source_metric: AsyncDelivery.metric_name(:stage, :total),
        total_matchers: [integration: :rindle, fault_plane: :worker],
        threshold: 0.03,
        alert_class: :warning,
        runbook: "https://parapet.dev/runbooks/rindle-funnel-regression",
        group_labels: [:integration, :provider, :queue, :pipeline_stage],
        labels: %{fault_plane: :worker},
        summary: "Rindle funnel regression is visible before it pages"
      )
    ]
  end
end
