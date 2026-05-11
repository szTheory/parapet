defmodule Parapet.Spine.Incident do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_incidents" do
    field :title, :string
    field :description, :string
    field :state, :string, default: "open"

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:title, :description, :state])
    |> validate_required([:title])
    |> validate_inclusion(:state, ["open", "investigating", "resolved"])
  end
end
