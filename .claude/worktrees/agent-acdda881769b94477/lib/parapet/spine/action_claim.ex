defmodule Parapet.Spine.ActionClaim do
  @moduledoc """
  Durable ownership record for a logical automation or escalation action.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Parapet.Spine.Incident

  @statuses [
    "claimed",
    "executed",
    "short_circuited",
    "claim_conflicted",
    "failed_retryable",
    "failed_terminal",
    "abandoned",
    "expired"
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_action_claims" do
    field(:action_kind, :string)
    field(:action_key, :string)
    field(:status, :string, default: "claimed")
    field(:idempotency_key, :string)
    field(:attempt_count, :integer, default: 1)
    field(:claimed_at, :utc_datetime_usec)
    field(:finished_at, :utc_datetime_usec)
    field(:short_circuit_reason, :string)
    field(:last_error_kind, :string)
    field(:last_error_message, :string)
    field(:error_metadata, :map, default: %{})

    belongs_to(:incident, Incident, type: :binary_id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(action_claim, attrs) do
    action_claim
    |> cast(attrs, [
      :incident_id,
      :action_kind,
      :action_key,
      :status,
      :idempotency_key,
      :attempt_count,
      :claimed_at,
      :finished_at,
      :short_circuit_reason,
      :last_error_kind,
      :last_error_message,
      :error_metadata
    ])
    |> validate_required([
      :incident_id,
      :action_kind,
      :action_key,
      :status,
      :idempotency_key,
      :attempt_count,
      :claimed_at
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:attempt_count, greater_than_or_equal_to: 1)
    |> unique_constraint([:incident_id, :action_kind, :action_key],
      name: :parapet_action_claims_incident_id_action_kind_action_key_index
    )
  end

  def statuses, do: @statuses
end
