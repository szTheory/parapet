defmodule Parapet.Telemetry.AsyncDelivery do
  @moduledoc """
  Public contract helpers for Parapet's async and delivery telemetry families.
  """

  @delivery_family_keys %{
    outbound: [:integration, :provider, :channel, :outcome, :failure_class, :fault_plane],
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
    ]
  }

  @async_family_keys %{
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

  @allowed_public_keys Map.merge(@delivery_family_keys, @async_family_keys)
  @event_families [
    [:parapet, :delivery, :outbound],
    [:parapet, :delivery, :provider_feedback],
    [:parapet, :delivery, :webhook_ingest],
    [:parapet, :async, :stage],
    [:parapet, :async, :backlog],
    [:parapet, :async, :callback]
  ]

  @delivery_outcomes %{
    attempted: :attempted,
    provider_accepted: :provider_accepted,
    accepted: :provider_accepted,
    delivered: :delivered,
    failed: :failed,
    bounced: :bounced,
    complained: :complained,
    suppressed: :suppressed
  }

  @async_outcomes %{
    started: :started,
    start: :started,
    succeeded: :succeeded,
    success: :succeeded,
    completed: :succeeded,
    retryable_failed: :retryable_failed,
    retryable: :retryable_failed,
    failed_retryable: :retryable_failed,
    discarded: :discarded,
    exhausted: :discarded,
    delayed: :delayed
  }

  @fault_planes %{
    provider: :provider,
    webhook: :webhook,
    suppression: :suppression,
    worker: :worker,
    backlog: :backlog
  }

  @retry_states %{
    first_attempt: :first_attempt,
    retrying: :retrying,
    exhausted: :exhausted
  }

  @allowed_ref_keys [
    :message_ref,
    :delivery_ref,
    :job_ref,
    :attempt_ref,
    :webhook_ref,
    :provider_request_ref,
    :provider_message_ref,
    :trace_ref,
    :run_ref,
    :incident_ref,
    :tenant_ref,
    :recipient_ref
  ]

  @known_ref_mappings %{
    attempt_id: :attempt_ref,
    delivery_id: :delivery_ref,
    incident_id: :incident_ref,
    job_id: :job_ref,
    message_id: :message_ref,
    provider_message_id: :provider_message_ref,
    provider_request_id: :provider_request_ref,
    recipient: :recipient_ref,
    recipient_id: :recipient_ref,
    run_id: :run_ref,
    tenant_id: :tenant_ref,
    trace_id: :trace_ref,
    webhook_id: :webhook_ref
  }

  def event_families, do: @event_families

  def event_name(family) when family in [:outbound, :provider_feedback, :webhook_ingest],
    do: [:parapet, :delivery, family]

  def event_name(family) when family in [:stage, :backlog, :callback],
    do: [:parapet, :async, family]

  def allowed_public_keys(family) when is_list(family) do
    family
    |> family_key()
    |> allowed_public_keys()
  end

  def allowed_public_keys(family) when is_atom(family) do
    Map.fetch!(@allowed_public_keys, family)
  end

  def normalize_delivery_outcome(outcome) do
    outcome
    |> normalize_enum(@delivery_outcomes, "delivery outcome")
  end

  def normalize_async_outcome(outcome) do
    outcome
    |> normalize_enum(@async_outcomes, "async outcome")
  end

  def normalize_fault_plane(plane) do
    plane
    |> normalize_enum(@fault_planes, "fault plane")
  end

  def normalize_retry_state(state) do
    state
    |> normalize_enum(@retry_states, "retry state")
  end

  def delay_bucket(delay_ms) when is_integer(delay_ms) and delay_ms >= 0 do
    cond do
      delay_ms < 1_000 -> :subsecond
      delay_ms < 30_000 -> :under_30s
      delay_ms < 300_000 -> :under_5m
      delay_ms < 3_600_000 -> :under_1h
      true -> :over_1h
    end
  end

  def delay_bucket(delay_ms) when is_float(delay_ms) and delay_ms >= 0 do
    delay_ms
    |> round()
    |> delay_bucket()
  end

  def shape_metadata(family, metadata) when is_list(family) do
    family
    |> family_key()
    |> shape_metadata(metadata)
  end

  def shape_metadata(family, metadata) when is_atom(family) and is_map(metadata) do
    public_keys = allowed_public_keys(family)

    public_metadata =
      metadata
      |> Map.take(public_keys)
      |> maybe_normalize_known_values()

    refs =
      metadata
      |> extract_known_refs()
      |> merge_explicit_refs(Map.get(metadata, :refs, %{}))

    if map_size(refs) == 0 do
      public_metadata
    else
      Map.put(public_metadata, :refs, refs)
    end
  end

  defp family_key([:parapet, :delivery, family]), do: family
  defp family_key([:parapet, :async, family]), do: family

  defp maybe_normalize_known_values(metadata) do
    metadata
    |> maybe_put(:outcome, &normalize_outcome_for_metadata/1)
    |> maybe_put(:fault_plane, &normalize_fault_plane/1)
    |> maybe_put(:retry_state, &normalize_retry_state/1)
  end

  defp maybe_put(metadata, key, fun) do
    case Map.fetch(metadata, key) do
      {:ok, value} -> Map.put(metadata, key, fun.(value))
      :error -> metadata
    end
  end

  defp normalize_outcome_for_metadata(outcome) do
    case Map.fetch(@delivery_outcomes, normalize_key(outcome)) do
      {:ok, normalized} -> normalized
      :error -> normalize_async_outcome(outcome)
    end
  end

  defp normalize_enum(value, mapping, label) do
    key = normalize_key(value)

    case Map.fetch(mapping, key) do
      {:ok, normalized} ->
        normalized

      :error ->
        raise ArgumentError, "Unsupported #{label}: #{inspect(value)}"
    end
  end

  defp normalize_key(value) when is_atom(value), do: value
  defp normalize_key(value) when is_binary(value), do: value |> String.trim() |> String.to_atom()

  defp extract_known_refs(metadata) do
    Enum.reduce(@known_ref_mappings, %{}, fn {source_key, ref_key}, refs ->
      case Map.get(metadata, source_key) do
        nil -> refs
        value -> Map.put(refs, ref_key, value)
      end
    end)
  end

  defp merge_explicit_refs(refs, explicit_refs) when is_map(explicit_refs) do
    explicit_refs
    |> Enum.reduce(refs, fn {key, value}, acc ->
      normalized_key = normalize_ref_key(key)

      if normalized_key in @allowed_ref_keys do
        Map.put(acc, normalized_key, value)
      else
        acc
      end
    end)
  end

  defp normalize_ref_key(key) when is_atom(key), do: key

  defp normalize_ref_key(key) when is_binary(key) do
    key
    |> String.trim()
    |> String.to_atom()
  end
end
