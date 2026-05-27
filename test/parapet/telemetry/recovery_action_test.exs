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
end
