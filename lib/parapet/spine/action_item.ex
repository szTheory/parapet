defmodule Parapet.Spine.ActionItem do
  @moduledoc """
  Core Ecto Schema representing an ActionItem for durable workflow approvals.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_action_items" do
    field(:title, :string)
    field(:integration, :string)
    field(:external_id, :string)
    field(:state, :string, default: "open")

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(action_item, attrs) do
    action_item
    |> cast(attrs, [:title, :integration, :external_id, :state])
    |> validate_required([:title, :integration, :external_id])
    |> validate_inclusion(:state, ["open", "resolved"])
  end
end
