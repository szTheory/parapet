defmodule Parapet.Telemetry.RecoveryActionTest do
  use ExUnit.Case, async: true

  alias Parapet.Telemetry.RecoveryAction

  test "exposes the eight frozen recovery action event families" do
    assert RecoveryAction.event_families() == [
             [:parapet, :operator, :recovery_action, :previewed],
             [:parapet, :operator, :recovery_action, :preview_failed],
             [:parapet, :operator, :recovery_action, :confirmed],
             [:parapet, :operator, :recovery_action, :short_circuited],
             [:parapet, :operator, :recovery_action, :conflicted],
             [:parapet, :operator, :recovery_action, :executed, :start],
             [:parapet, :operator, :recovery_action, :executed, :stop],
             [:parapet, :operator, :recovery_action, :executed, :exception]
           ]
  end

  test "normalizes bounded outcome, short_circuit_reason, and failure_class atoms only" do
    assert RecoveryAction.normalize_outcome(:succeeded) == :succeeded
    assert RecoveryAction.normalize_outcome(:failed) == :failed
    assert RecoveryAction.normalize_outcome(:previewed) == :previewed

    assert_raise ArgumentError, ~r/Unsupported outcome/, fn ->
      RecoveryAction.normalize_outcome(:bogus_outcome)
    end

    assert RecoveryAction.normalize_short_circuit_reason(:incident_resolved) == :incident_resolved
    assert RecoveryAction.normalize_short_circuit_reason(:breaker_open) == :breaker_open

    assert_raise ArgumentError, ~r/Unsupported short_circuit_reason/, fn ->
      RecoveryAction.normalize_short_circuit_reason(:bogus_reason)
    end

    assert RecoveryAction.normalize_failure_class(:precondition_failed) == :precondition_failed
    assert RecoveryAction.normalize_failure_class(:internal_error) == :internal_error

    assert_raise ArgumentError, ~r/Unsupported failure_class/, fn ->
      RecoveryAction.normalize_failure_class(:bogus_class)
    end

    assert RecoveryAction.normalize_actor_kind(:human) == :human
    assert RecoveryAction.normalize_actor_kind(:system) == :system

    assert_raise ArgumentError, ~r/Unsupported actor_kind/, fn ->
      RecoveryAction.normalize_actor_kind(:bogus_actor)
    end

    assert RecoveryAction.normalize_action_kind(:operator) == "operator"
    assert RecoveryAction.normalize_action_kind(:automation) == "automation"

    assert_raise ArgumentError, ~r/Unsupported action_kind/, fn ->
      RecoveryAction.normalize_action_kind(:bogus_action)
    end
  end

  test "shapes metadata into public keys, builds refs sub-map, and strips private keys" do
    shaped =
      RecoveryAction.shape_metadata(:previewed, %{
        capability_id: :retry_async_item,
        action_kind: :operator,
        outcome: :previewed,
        incident_id: "inc-123",
        refs: %{step_ref: "step-9", bogus_ref: "filtered"},
        internal_debug: "ignored"
      })

    assert shaped.capability_id == :retry_async_item
    assert shaped.outcome == :previewed
    assert shaped.refs == %{incident_ref: "inc-123", step_ref: "step-9"}
    refute Map.has_key?(shaped, :internal_debug)
  end

  test "exposes the executed span family" do
    assert [:parapet, :operator, :recovery_action, :executed] in RecoveryAction.span_families()

    assert RecoveryAction.allowed_public_keys([:parapet, :operator, :recovery_action, :executed, :stop]) ==
             RecoveryAction.allowed_public_keys(:executed)
  end

  test "allowed_public_keys/1 raises a clear ArgumentError for unrecognized event name shapes" do
    # WR-02 regression: a malformed event name list (e.g. bare family list, typo,
    # or wrong shape) used to surface as an opaque FunctionClauseError. It must
    # now raise ArgumentError naming the offending value and the expected shapes.
    assert_raise ArgumentError, ~r/Unsupported recovery_action event name/, fn ->
      RecoveryAction.allowed_public_keys([:previewed])
    end

    assert_raise ArgumentError, ~r/Unsupported recovery_action event name/, fn ->
      RecoveryAction.allowed_public_keys([:parapet, :operator, :recovery_action, :typo, :extra])
    end
  end

  test "shape_metadata/2 raises a clear ArgumentError for unrecognized event name shapes" do
    # WR-02 regression: same property for shape_metadata/2 — the other public
    # entry point that funnels through family_key/1.
    assert_raise ArgumentError, ~r/Unsupported recovery_action event name/, fn ->
      RecoveryAction.shape_metadata([:wrong, :shape], %{capability_id: :retry_async_item})
    end
  end

  test "normalize_outcome/1 does not create atoms for the poison binary itself (atom-table safety)" do
    # CR-01 regression: a malicious or buggy upstream sending attacker-controlled
    # strings to the normalize_*/1 helpers must NOT leak atoms. The helpers must
    # raise ArgumentError for unknown inputs WITHOUT minting a fresh atom in the
    # global table (which is never garbage-collected and capped at ~1M entries).
    #
    # We assert this property TWO ways:
    #
    # 1. After rejection, the poison string itself MUST NOT exist as an atom
    #    (the most direct check; not sensitive to test-infrastructure atoms).
    # 2. After a warm-up pass + measurement, atom_count is stable across
    #    repeated rejections of FRESH poison strings (proves the helper is the
    #    non-leaking path).
    poison = "definitely-not-a-known-atom-#{System.unique_integer([:positive])}"

    assert_raise ArgumentError, ~r/Unsupported outcome/, fn ->
      RecoveryAction.normalize_outcome(poison)
    end

    # Direct check: poison was never interned. This is the load-bearing
    # assertion — if String.to_atom were still in the code path, this would
    # succeed (returning the atom) instead of raising.
    assert_raise ArgumentError, fn -> String.to_existing_atom(poison) end

    # Warm-up: run one rejection pass to let assert_raise + error-message
    # machinery intern any of their own internal atoms. THEN measure stability
    # over a second rejection pass with a fresh poison string.
    warmup_poison = "warmup-poison-#{System.unique_integer([:positive])}"

    assert_raise ArgumentError, fn ->
      RecoveryAction.normalize_outcome(warmup_poison)
    end

    poison_2 = "second-poison-#{System.unique_integer([:positive])}"
    before_count = :erlang.system_info(:atom_count)

    assert_raise ArgumentError, fn ->
      RecoveryAction.normalize_outcome(poison_2)
    end

    after_count = :erlang.system_info(:atom_count)

    assert after_count == before_count,
           "normalize_outcome leaked atoms on second pass: #{before_count} → #{after_count} " <>
             "(poison=#{inspect(poison_2)}). String.to_atom/1 must not be called before " <>
             "the closed-vocabulary lookup."
  end

  test "normalize_*/1 helpers raise ArgumentError for unknown binary inputs (no fresh atom interned)" do
    # CR-01 regression: every normalize_*/1 helper that accepts a binary must
    # reject unknown inputs WITHOUT interning the input string as an atom.
    poisons = %{
      normalize_outcome: "evil-outcome-#{System.unique_integer([:positive])}",
      normalize_short_circuit_reason: "evil-sc-#{System.unique_integer([:positive])}",
      normalize_failure_class: "evil-fc-#{System.unique_integer([:positive])}",
      normalize_actor_kind: "evil-ak-#{System.unique_integer([:positive])}",
      normalize_action_kind: "evil-act-#{System.unique_integer([:positive])}"
    }

    for {fun, poison} <- poisons do
      assert_raise ArgumentError, fn ->
        apply(RecoveryAction, fun, [poison])
      end

      # Direct check: each poison string was NOT interned by the helper.
      assert_raise ArgumentError, fn -> String.to_existing_atom(poison) end
    end
  end

  test "shape_metadata accepts refs: nil as no-op" do
    # WR-01 regression: refs: nil must be treated as "no explicit refs"
    # instead of crashing with FunctionClauseError.
    shaped =
      RecoveryAction.shape_metadata(:previewed, %{
        capability_id: :retry_async_item,
        incident_id: "inc-1",
        refs: nil
      })

    assert shaped.refs == %{incident_ref: "inc-1"}
  end

  test "shape_metadata accepts refs as a keyword list" do
    # WR-01 regression: keyword lists are idiomatic in Elixir telemetry
    # metadata and must be coerced to a map cleanly.
    shaped =
      RecoveryAction.shape_metadata(:previewed, %{
        capability_id: :retry_async_item,
        refs: [step_ref: "step-9", incident_ref: "inc-2"]
      })

    assert shaped.refs == %{step_ref: "step-9", incident_ref: "inc-2"}
  end

  test "shape_metadata raises ArgumentError for non-map / non-keyword refs" do
    # WR-01 regression: invalid refs shapes get an actionable diagnostic,
    # not an opaque FunctionClauseError.
    assert_raise ArgumentError, ~r/refs must be a map, keyword list, or nil/, fn ->
      RecoveryAction.shape_metadata(:previewed, %{
        capability_id: :retry_async_item,
        refs: "step-9"
      })
    end

    assert_raise ArgumentError, ~r/refs must be a map, keyword list, or nil/, fn ->
      RecoveryAction.shape_metadata(:previewed, %{
        capability_id: :retry_async_item,
        refs: [1, 2, 3]
      })
    end
  end

  test "shape_metadata silently drops unknown ref keys without interning them as atoms" do
    # CR-01 regression for normalize_ref_key/1: explicit refs with unknown string
    # keys must be silently dropped (matching documented behavior) and MUST NOT
    # mint a fresh atom.
    poison_key = "evil-ref-key-#{System.unique_integer([:positive])}"

    shaped =
      RecoveryAction.shape_metadata(:previewed, %{
        capability_id: :retry_async_item,
        refs: %{poison_key => "should-be-dropped", "step_ref" => "step-9"}
      })

    # The unknown ref key was silently dropped, and is NOT now interned as an atom.
    # If String.to_atom/1 were still in normalize_ref_key/1, the poison_key would
    # exist as an atom and to_existing_atom would succeed.
    assert_raise ArgumentError, fn -> String.to_existing_atom(poison_key) end

    # Known ref key (string form) is still accepted via to_existing_atom.
    assert shaped.refs == %{step_ref: "step-9"}
  end
end
