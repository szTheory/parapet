defmodule Parapet.Spine.SystemEvent do
  @moduledoc """
  Ecto schema representing a general system event (like a flag mutation or deployment).
  These are buffered and pruned periodically.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
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
