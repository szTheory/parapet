defmodule Parapet.Telemetry.RecoveryAction do
  @moduledoc """
  Public contract helpers for Parapet's recovery action telemetry family.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.

  ## Measurement Convention

  `duration_ms` and `duration_native` are the project's CONVENTION for span events —
  handlers convert the raw `:telemetry.span/3` `duration` (native units) into both
  `duration_ms` (integer) and `duration_native` (integer) before re-emitting. Phase 26
  emit-sites will call `:telemetry.span/3` directly; the project's instrumenter converts
  before downstream subscribers see the payload. Adopters subscribing to these events
  should expect `duration_ms` + `duration_native` on `:stop`/`:exception`, and
  `system_time` (integer) on `:start`.
  """

  @event_families [
    [:parapet, :operator, :recovery_action, :previewed],
    [:parapet, :operator, :recovery_action, :preview_failed],
    [:parapet, :operator, :recovery_action, :confirmed],
    [:parapet, :operator, :recovery_action, :short_circuited],
    [:parapet, :operator, :recovery_action, :conflicted],
    [:parapet, :operator, :recovery_action, :executed, :start],
    [:parapet, :operator, :recovery_action, :executed, :stop],
    [:parapet, :operator, :recovery_action, :executed, :exception]
  ]

  @span_families [
    [:parapet, :operator, :recovery_action, :executed]
  ]

  @outcomes %{
    previewed: :previewed,
    confirmed: :confirmed,
    short_circuited: :short_circuited,
    conflicted: :conflicted,
    succeeded: :succeeded,
    failed: :failed
  }

  @short_circuit_reasons %{
    incident_resolved: :incident_resolved,
    breaker_open: :breaker_open,
    preview_expired: :preview_expired,
    target_refs_drift: :target_refs_drift
  }

  @failure_classes %{
    precondition_failed: :precondition_failed,
    provider_unavailable: :provider_unavailable,
    partial_failure: :partial_failure,
    internal_error: :internal_error
  }

  @actor_kinds %{
    human: :human,
    system: :system
  }

  @action_kinds %{
    operator: "operator",
    automation: "automation",
    escalation: "escalation"
  }

  @allowed_ref_keys [
    :incident_ref,
    :claim_ref,
    :step_ref,
    :preview_ref
  ]

  @known_ref_mappings %{
    incident_id: :incident_ref,
    claim_id: :claim_ref,
    step_id: :step_ref,
    preview_id: :preview_ref
  }

  @recovery_action_family_keys %{
    previewed: [:capability_id, :action_kind, :outcome, :actor_kind],
    preview_failed: [:capability_id, :action_kind, :outcome, :failure_class, :actor_kind],
    confirmed: [:capability_id, :action_kind, :outcome, :actor_kind],
    short_circuited: [:capability_id, :action_kind, :outcome, :short_circuit_reason, :actor_kind],
    conflicted: [:capability_id, :action_kind, :outcome, :actor_kind],
    executed: [:capability_id, :action_kind, :outcome, :failure_class, :actor_kind]
  }

  @allowed_public_keys @recovery_action_family_keys

  @doc since: "1.1.0"
  @doc """
  Returns the list of all eight frozen recovery action telemetry event name tuples
  (the executed span counts as one logical family with three sub-events).
  """
  def event_families, do: @event_families

  @doc since: "1.1.0"
  @doc """
  Returns the list of span telemetry family base tuples for recovery actions.
  These families are emitted via `:telemetry.span/3` and have three sub-events
  (`:start`, `:stop`, `:exception`).
  """
  def span_families, do: @span_families

  @doc since: "1.1.0"
  @doc """
  Returns the list of allowed public metadata keys for a given event family.
  Accepts either a full event name list (e.g. `[:parapet, :operator, :recovery_action, :previewed]`)
  or a family atom (e.g. `:previewed`).
  """
  def allowed_public_keys(family) when is_list(family) do
    family
    |> family_key()
    |> allowed_public_keys()
  end

  def allowed_public_keys(family) when is_atom(family) do
    Map.fetch!(@allowed_public_keys, family)
  end

  @doc since: "1.1.0"
  @doc """
  Shapes a raw metadata map for a given event family into the public-key-only metadata map
  expected in the telemetry event. Strips private/internal keys, normalizes known values, and
  collects ref keys under a `:refs` sub-map. Accepts either a full event name list or a family
  atom.
  """
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

  @doc since: "1.1.0"
  @doc """
  Normalizes an outcome atom or string to its canonical form.
  Raises `ArgumentError` for unknown outcomes.

  Valid outcomes: `:previewed`, `:confirmed`, `:short_circuited`, `:conflicted`,
  `:succeeded`, `:failed`.
  """
  def normalize_outcome(outcome) do
    outcome |> normalize_enum(@outcomes, "outcome")
  end

  @doc since: "1.1.0"
  @doc """
  Normalizes a short circuit reason atom or string to its canonical form.
  Raises `ArgumentError` for unknown short circuit reasons.

  Valid reasons: `:incident_resolved`, `:breaker_open`, `:preview_expired`,
  `:target_refs_drift`.
  """
  def normalize_short_circuit_reason(reason) do
    reason |> normalize_enum(@short_circuit_reasons, "short_circuit_reason")
  end

  @doc since: "1.1.0"
  @doc """
  Normalizes a failure class atom or string to its canonical form.
  Raises `ArgumentError` for unknown failure classes.

  Valid classes: `:precondition_failed`, `:provider_unavailable`, `:partial_failure`,
  `:internal_error`.
  """
  def normalize_failure_class(failure_class) do
    failure_class |> normalize_enum(@failure_classes, "failure_class")
  end

  @doc since: "1.1.0"
  @doc """
  Normalizes an actor kind atom or string to its canonical form.
  Raises `ArgumentError` for unknown actor kinds.

  Valid kinds: `:human`, `:system`.
  """
  def normalize_actor_kind(actor_kind) do
    actor_kind |> normalize_enum(@actor_kinds, "actor_kind")
  end

  @doc since: "1.1.0"
  @doc """
  Normalizes an action kind atom or string to its canonical string form.
  Raises `ArgumentError` for unknown action kinds.

  Valid kinds: `:operator` ("operator"), `:automation` ("automation"),
  `:escalation` ("escalation").
  """
  def normalize_action_kind(action_kind) do
    action_kind |> normalize_enum(@action_kinds, "action_kind")
  end

  # Extracts the family key atom from a full event name tuple.
  # Single-shot events: returns the last atom (e.g. :previewed).
  # Span sub-events: returns :executed for all three sub-events.
  defp family_key([:parapet, :operator, :recovery_action, :executed, _sub]), do: :executed
  defp family_key([:parapet, :operator, :recovery_action, family]), do: family

  defp maybe_normalize_known_values(metadata) do
    metadata
    |> maybe_put(:outcome, &normalize_outcome/1)
    |> maybe_put(:short_circuit_reason, &normalize_short_circuit_reason/1)
    |> maybe_put(:failure_class, &normalize_failure_class/1)
    |> maybe_put(:actor_kind, &normalize_actor_kind/1)
    |> maybe_put(:action_kind, &normalize_action_kind/1)
  end

  defp maybe_put(metadata, key, fun) do
    case Map.fetch(metadata, key) do
      {:ok, value} -> Map.put(metadata, key, fun.(value))
      :error -> metadata
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

  defp normalize_key(value) when is_binary(value) do
    # Use to_existing_atom (NOT to_atom) to prevent atom-table exhaustion from
    # adopter input. All legal vocabulary atoms (@outcomes, @short_circuit_reasons,
    # @failure_classes, @actor_kinds, @action_kinds keys) are interned at module
    # compile time. Unknown strings collapse to the :__unknown__ sentinel which
    # then fails the Map.fetch lookup in normalize_enum/3 → raises the documented
    # ArgumentError without minting a new atom.
    String.to_existing_atom(String.trim(value))
  rescue
    ArgumentError -> :__unknown__
  end

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
    # Use to_existing_atom (NOT to_atom) to prevent atom-table exhaustion from
    # adopter input. Unknown ref keys collapse to :__unknown__, which fails the
    # `in @allowed_ref_keys` check in merge_explicit_refs/2 and is silently
    # dropped — matching the documented "unknown keys are dropped" semantics
    # without minting a new atom.
    String.to_existing_atom(String.trim(key))
  rescue
    ArgumentError -> :__unknown__
  end
end
