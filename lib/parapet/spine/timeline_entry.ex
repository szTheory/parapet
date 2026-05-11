defmodule Parapet.Spine.TimelineEntry do
  @moduledoc """
  Ecto schema representing an entry in a durable incident timeline.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Parapet.Spine.Incident

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_timeline_entries" do
    field :type, :string
    field :payload, :map

    belongs_to :incident, Incident, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(timeline_entry, attrs) do
    timeline_entry
    |> cast(attrs, [:type, :payload, :incident_id])
    |> validate_required([:type, :incident_id])
  end
end
