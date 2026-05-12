defmodule Parapet.Spine.Incident do
  @moduledoc """
  Ecto schema representing a durable evidence incident.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_incidents" do
    field :title, :string
    field :description, :string
    field :state, :string, default: "open"
    field :correlation_key, :string
    field :runbook_data, :map

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:title, :description, :state, :correlation_key, :runbook_data])
    |> validate_required([:title])
    |> validate_inclusion(:state, ["open", "investigating", "resolved"])
  end
end
