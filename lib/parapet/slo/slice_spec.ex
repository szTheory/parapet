defmodule Parapet.SLO.SliceSpec do
  @moduledoc """
  Bounded provider-owned slice description for Phase 5 generators.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. Its public API will not change without a
  > major-version bump and a full deprecation cycle. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @kinds [:ratio, :freshness, :diagnostic]
  @alert_classes [:page, :ticket, :warning, :diagnostic]

  @enforce_keys [:name, :integration, :kind, :alert_class, :runbook]
  defstruct [
    :name,
    :integration,
    :kind,
    :objective,
    :alert_class,
    :runbook,
    :good_source_metric,
    :bad_source_metric,
    :total_source_metric,
    :threshold,
    :summary,
    group_labels: [:integration],
    labels: %{},
    good_matchers: [],
    bad_matchers: [],
    total_matchers: [],
    min_total_rate: 0.01,
    for: nil,
    keep_firing_for: nil
  ]

  @type t :: %__MODULE__{}

  @doc since: "1.0.0"
  @doc """
  Builds a validated `Parapet.SLO.SliceSpec` struct from a keyword list of options.
  Raises `ArgumentError` if required fields are missing or invalid.
  """
  def new(opts) do
    opts =
      opts
      |> maybe_expand_shared_metric()
      |> Keyword.put_new(:labels, %{})
      |> Keyword.put_new(:group_labels, [:integration])
      |> Keyword.put_new(:good_matchers, [])
      |> Keyword.put_new(:bad_matchers, [])
      |> Keyword.put_new(:total_matchers, [])
      |> Keyword.put_new(:min_total_rate, 0.01)

    spec = struct!(__MODULE__, opts)
    validate!(spec)
  end

  @doc since: "1.0.0"
  @doc """
  Returns `true` if this slice is a `:diagnostic` kind slice, `false` otherwise.
  """
  def diagnostic?(%__MODULE__{kind: :diagnostic}), do: true
  def diagnostic?(%__MODULE__{}), do: false

  @doc since: "1.0.0"
  @doc """
  Returns the primary metric name for this slice. For diagnostic slices, returns the bad metric;
  for ratio slices, returns the good metric.
  """
  def value_metric(%__MODULE__{kind: :diagnostic, bad_source_metric: metric}), do: metric
  def value_metric(%__MODULE__{good_source_metric: metric}), do: metric

  @doc since: "1.0.0"
  @doc """
  Returns the primary label matchers for this slice. For diagnostic slices, returns the bad
  matchers; for ratio slices, returns the good matchers.
  """
  def value_matchers(%__MODULE__{kind: :diagnostic, bad_matchers: matchers}), do: matchers
  def value_matchers(%__MODULE__{good_matchers: matchers}), do: matchers

  @doc since: "1.0.0"
  @doc """
  Returns the error threshold for this slice as a fraction between 0 and 1.
  If an explicit `:threshold` is set, it is returned directly. Otherwise it is derived
  from `:objective` as `1 - objective / 100`.
  """
  def threshold(%__MODULE__{threshold: threshold}) when is_number(threshold), do: threshold

  def threshold(%__MODULE__{objective: objective}) when is_number(objective) do
    1 - objective / 100
  end

  @doc since: "1.0.0"
  @doc """
  Returns the Prometheus alerting severity label string for this slice's alert class.
  """
  def severity(%__MODULE__{alert_class: :page}), do: "page"
  def severity(%__MODULE__{alert_class: :ticket}), do: "ticket"
  def severity(%__MODULE__{alert_class: :warning}), do: "warning"
  def severity(%__MODULE__{alert_class: :diagnostic}), do: "warning"

  @doc since: "1.0.0"
  @doc """
  Returns the default `for:` duration string for the Prometheus alert rule based on alert class.
  """
  def default_for(%__MODULE__{alert_class: :page}), do: "10m"
  def default_for(%__MODULE__{alert_class: :ticket}), do: "20m"
  def default_for(%__MODULE__{alert_class: :warning}), do: "30m"
  def default_for(%__MODULE__{alert_class: :diagnostic}), do: "15m"

  @doc since: "1.0.0"
  @doc """
  Returns the default `keep_firing_for:` duration string for the Prometheus alert rule based
  on alert class.
  """
  def default_keep_firing_for(%__MODULE__{alert_class: :page}), do: "5m"
  def default_keep_firing_for(%__MODULE__{alert_class: :ticket}), do: "10m"
  def default_keep_firing_for(%__MODULE__{alert_class: :warning}), do: "15m"
  def default_keep_firing_for(%__MODULE__{alert_class: :diagnostic}), do: "10m"

  defp maybe_expand_shared_metric(opts) do
    case Keyword.fetch(opts, :source_metric) do
      {:ok, metric} ->
        opts
        |> Keyword.put_new(:good_source_metric, metric)
        |> Keyword.put_new(:bad_source_metric, metric)
        |> Keyword.put_new(:total_source_metric, metric)
        |> Keyword.delete(:source_metric)

      :error ->
        opts
    end
  end

  defp validate!(%__MODULE__{} = spec) do
    unless spec.kind in @kinds do
      raise ArgumentError, "unsupported slice kind #{inspect(spec.kind)}"
    end

    unless spec.alert_class in @alert_classes do
      raise ArgumentError, "unsupported alert class #{inspect(spec.alert_class)}"
    end

    validate_metric_fields!(spec)
    validate_threshold!(spec)

    unless is_list(spec.group_labels) and spec.group_labels != [] do
      raise ArgumentError, "slice spec #{spec.name} requires at least one group label"
    end

    spec
  end

  defp validate_metric_fields!(%__MODULE__{kind: :diagnostic} = spec) do
    if is_nil(spec.bad_source_metric) or spec.bad_matchers == [] do
      raise ArgumentError, "diagnostic slice #{spec.name} requires bad matchers and metric"
    end

    if is_nil(spec.total_source_metric) or spec.total_matchers == [] do
      raise ArgumentError, "diagnostic slice #{spec.name} requires total matchers and metric"
    end
  end

  defp validate_metric_fields!(%__MODULE__{} = spec) do
    if is_nil(spec.good_source_metric) or spec.good_matchers == [] do
      raise ArgumentError, "slice #{spec.name} requires good matchers and metric"
    end

    if is_nil(spec.total_source_metric) or spec.total_matchers == [] do
      raise ArgumentError, "slice #{spec.name} requires total matchers and metric"
    end
  end

  defp validate_threshold!(%__MODULE__{threshold: threshold, objective: objective, kind: kind, name: name}) do
    cond do
      is_number(threshold) ->
        :ok

      is_number(objective) ->
        :ok

      kind == :diagnostic ->
        raise ArgumentError, "diagnostic slice #{name} requires threshold or objective"

      true ->
        raise ArgumentError, "slice #{name} requires objective"
    end
  end
end
