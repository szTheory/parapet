defmodule Parapet.Spine.ActionClaimTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.ActionClaim

  test "changeset accepts bounded lifecycle attributes" do
    claimed_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    changeset =
      ActionClaim.changeset(%ActionClaim{}, %{
        incident_id: Ecto.UUID.generate(),
        action_kind: "automation",
        action_key: "step-1",
        status: "claimed",
        idempotency_key: "auto_exec_incident_step-1",
        attempt_count: 1,
        claimed_at: claimed_at
      })

    assert changeset.valid?
  end

  test "changeset rejects unsupported status values" do
    changeset =
      ActionClaim.changeset(%ActionClaim{}, %{
        incident_id: Ecto.UUID.generate(),
        action_kind: "automation",
        action_key: "step-1",
        status: "looping",
        idempotency_key: "auto_exec_incident_step-1",
        attempt_count: 1,
        claimed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })

    refute changeset.valid?
    assert "is invalid" in errors_on(changeset).status
  end

  test "changeset requires a positive attempt count" do
    changeset =
      ActionClaim.changeset(%ActionClaim{}, %{
        incident_id: Ecto.UUID.generate(),
        action_kind: "automation",
        action_key: "step-1",
        status: "claimed",
        idempotency_key: "auto_exec_incident_step-1",
        attempt_count: 0,
        claimed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })

    refute changeset.valid?
    assert "must be greater than or equal to 1" in errors_on(changeset).attempt_count
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
