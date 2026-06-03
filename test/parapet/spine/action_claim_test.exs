defmodule Parapet.Spine.ActionClaimTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.ActionClaim

  test "changeset accepts bounded lifecycle attributes" do
    claimed_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    lease_until = DateTime.add(claimed_at, 5 * 60, :second) |> DateTime.truncate(:microsecond)

    changeset =
      ActionClaim.changeset(%ActionClaim{}, %{
        incident_id: Ecto.UUID.generate(),
        action_kind: "automation",
        action_key: "step-1",
        status: "claimed",
        idempotency_key: "auto_exec_incident_step-1",
        attempt_count: 1,
        claimed_at: claimed_at,
        lease_until: lease_until
      })

    assert changeset.valid?
  end

  test "changeset rejects unsupported status values" do
    # WR-03: include lease_until so the only invalid-changeset reason
    # is the status validation under test. Without this, the prior version
    # of this test passed for two reasons (missing lease_until AND invalid
    # status), so a regression in status validation would not have failed
    # this test.
    claimed_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    lease_until = DateTime.add(claimed_at, 5 * 60, :second) |> DateTime.truncate(:microsecond)

    changeset =
      ActionClaim.changeset(%ActionClaim{}, %{
        incident_id: Ecto.UUID.generate(),
        action_kind: "automation",
        action_key: "step-1",
        status: "looping",
        idempotency_key: "auto_exec_incident_step-1",
        attempt_count: 1,
        claimed_at: claimed_at,
        lease_until: lease_until
      })

    refute changeset.valid?
    assert "is invalid" in errors_on(changeset).status
  end

  test "changeset requires a positive attempt count" do
    # WR-03: include lease_until so the only invalid-changeset reason
    # is the attempt_count validation under test.
    claimed_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    lease_until = DateTime.add(claimed_at, 5 * 60, :second) |> DateTime.truncate(:microsecond)

    changeset =
      ActionClaim.changeset(%ActionClaim{}, %{
        incident_id: Ecto.UUID.generate(),
        action_kind: "automation",
        action_key: "step-1",
        status: "claimed",
        idempotency_key: "auto_exec_incident_step-1",
        attempt_count: 0,
        claimed_at: claimed_at,
        lease_until: lease_until
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
