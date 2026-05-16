defmodule Parapet.Spine.SystemEvent do
  @moduledoc """
  Ecto schema representing a general system event (like a flag mutation or deployment).
  These are buffered and pruned periodically.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_system_events" do
    field(:type, :string)
    field(:payload, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(system_event, attrs) do
    system_event
    |> cast(attrs, [:type, :payload])
    |> validate_required([:type])
  end
end
