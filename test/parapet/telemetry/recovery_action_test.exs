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

  test "normalize_outcome/1 does not create atoms for unknown binary inputs (atom-table safety)" do
    # CR-01 regression: a malicious or buggy upstream sending attacker-controlled
    # strings to the normalize_*/1 helpers must NOT leak atoms. The helpers must
    # raise ArgumentError for unknown inputs WITHOUT minting a fresh atom in the
    # global table (which is never garbage-collected and capped at ~1M entries).
    #
    # Use a string that is overwhelmingly unlikely to already be interned. If it
    # somehow IS already interned (e.g., the test runner created it), the
    # atom_count delta will still be zero — that's also a passing condition.
    poison = "definitely-not-a-known-atom-#{System.unique_integer([:positive])}"

    before_count = :erlang.system_info(:atom_count)

    assert_raise ArgumentError, ~r/Unsupported outcome/, fn ->
      RecoveryAction.normalize_outcome(poison)
    end

    after_count = :erlang.system_info(:atom_count)

    assert after_count == before_count,
           "normalize_outcome leaked atoms: atom_count went from #{before_count} to #{after_count} " <>
             "after rejecting unknown binary #{inspect(poison)}. " <>
             "This indicates String.to_atom/1 was called before validating against the closed vocabulary."

    # Belt-and-suspenders: the same atom should not be present at all.
    assert_raise ArgumentError, fn -> String.to_existing_atom(poison) end
  end

  test "normalize_*/1 helpers raise ArgumentError for unknown binary inputs without leaking atoms" do
    # CR-01 regression: apply the same property to every normalize_*/1 helper
    # that accepts binary input.
    poisons = %{
      normalize_outcome: "evil-outcome-#{System.unique_integer([:positive])}",
      normalize_short_circuit_reason: "evil-sc-#{System.unique_integer([:positive])}",
      normalize_failure_class: "evil-fc-#{System.unique_integer([:positive])}",
      normalize_actor_kind: "evil-ak-#{System.unique_integer([:positive])}",
      normalize_action_kind: "evil-act-#{System.unique_integer([:positive])}"
    }

    before_count = :erlang.system_info(:atom_count)

    for {fun, poison} <- poisons do
      assert_raise ArgumentError, fn ->
        apply(RecoveryAction, fun, [poison])
      end
    end

    after_count = :erlang.system_info(:atom_count)

    assert after_count == before_count,
           "RecoveryAction normalize_*/1 helpers leaked #{after_count - before_count} atoms"
  end

  test "shape_metadata silently drops unknown ref keys without leaking atoms" do
    # CR-01 regression for normalize_ref_key/1: explicit refs with unknown string
    # keys must be silently dropped (matching documented behavior) and MUST NOT
    # mint a fresh atom.
    poison_key = "evil-ref-key-#{System.unique_integer([:positive])}"

    before_count = :erlang.system_info(:atom_count)

    shaped =
      RecoveryAction.shape_metadata(:previewed, %{
        capability_id: :retry_async_item,
        refs: %{poison_key => "should-be-dropped", "step_ref" => "step-9"}
      })

    after_count = :erlang.system_info(:atom_count)

    assert after_count == before_count,
           "shape_metadata leaked atoms via unknown ref key: #{before_count} → #{after_count}"

    # Known ref key (string form) is still accepted via to_existing_atom.
    assert shaped.refs == %{step_ref: "step-9"}
  end
end
