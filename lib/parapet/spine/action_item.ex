defmodule Parapet.Spine.ActionItem do
  @moduledoc """
  Core Ecto Schema representing an ActionItem for durable workflow approvals.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Parapet.Spine.Incident

  @kinds [
    "exact_follow_up",
    "suppressed_delivery",
    "stalled_workflow",
    "orphaned_callback",
    "dead_letter"
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_action_items" do
    field(:title, :string)
    field(:integration, :string)
    field(:external_id, :string)
    field(:kind, :string, default: "exact_follow_up")
    field(:state, :string, default: "open")

    belongs_to(:incident, Incident, type: :binary_id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(action_item, attrs) do
    action_item
    |> cast(attrs, [:title, :integration, :external_id, :kind, :state, :incident_id])
    |> validate_required([:title, :integration, :external_id])
    |> validate_inclusion(:state, ["open", "resolved"])
    |> validate_inclusion(:kind, @kinds)
  end
end
