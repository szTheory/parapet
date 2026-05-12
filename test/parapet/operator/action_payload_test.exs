defmodule Parapet.Operator.ActionPayloadTest do
  use ExUnit.Case, async: true
  alias Parapet.Operator.ActionPayload

  describe "validation" do
    test "Valid payloads require actor, reason, and correlation_id, and permit optional idempotency metadata" do
      attrs = %{
        actor: "user_123",
        reason: "Investigating spike in errors",
        correlation_id: "req_abc",
        idempotency_key: "idemp_123",
        action_type: :immutable_fact
      }

      changeset = ActionPayload.changeset(%ActionPayload{}, attrs)
      assert changeset.valid?

      payload = Ecto.Changeset.apply_changes(changeset)
      assert payload.actor == "user_123"
      assert payload.idempotency_key == "idemp_123"
    end

    test "Missing or blank audit metadata returns an error/invalid changeset before any mutation call path can proceed" do
      attrs = %{
        actor: "",
        reason: nil,
        action_type: :immutable_fact
      }

      changeset = ActionPayload.changeset(%ActionPayload{}, attrs)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "can't be blank" in errors.actor
      assert "can't be blank" in errors.reason
      assert "can't be blank" in errors.correlation_id
    end

    test "Payload validation distinguishes immutable factual actions from lightweight narrative edits" do
      # action_type must be either :immutable_fact or :narrative_edit
      fact_changeset =
        ActionPayload.changeset(%ActionPayload{}, %{
          actor: "user_1",
          reason: "testing",
          correlation_id: "c-1",
          action_type: :immutable_fact
        })

      assert fact_changeset.valid?

      edit_changeset =
        ActionPayload.changeset(%ActionPayload{}, %{
          actor: "user_1",
          reason: "fixing typo",
          correlation_id: "c-2",
          action_type: :narrative_edit
        })

      assert edit_changeset.valid?

      invalid_changeset =
        ActionPayload.changeset(%ActionPayload{}, %{
          actor: "user_1",
          reason: "bad type",
          correlation_id: "c-3",
          action_type: :unknown_type
        })

      refute invalid_changeset.valid?

      errors = Ecto.Changeset.traverse_errors(invalid_changeset, fn {msg, _opts} -> msg end)
      assert "is invalid" in errors.action_type
    end
  end
end
