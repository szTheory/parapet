defmodule Parapet.Operator.ActionPayload do
  @moduledoc """
  Shared action payload contract for operator commands.
  Ensures that every mutating operator command provides mandatory
  audit metadata (actor, reason, correlation_id) and distinguishes
  between immutable factual actions and lightweight narrative edits.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :actor, :string
    field :reason, :string
    field :correlation_id, :string
    field :idempotency_key, :string
    
    # Determines if the action writes an immutable fact (e.g. change marker, resolution)
    # or a narrative edit (e.g. updating description).
    field :action_type, Ecto.Enum, values: [:immutable_fact, :narrative_edit]
  end

  @doc """
  Builds and validates an action payload changeset.
  """
  def changeset(payload \\ %__MODULE__{}, attrs) do
    payload
    |> cast(attrs, [:actor, :reason, :correlation_id, :idempotency_key, :action_type])
    |> validate_required([:actor, :reason, :correlation_id, :action_type])
    |> validate_not_blank(:actor)
    |> validate_not_blank(:reason)
    |> validate_not_blank(:correlation_id)
  end

  defp validate_not_blank(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if is_binary(value) and String.trim(value) == "" do
        [{field, "can't be blank"}]
      else
        []
      end
    end)
  end
end
