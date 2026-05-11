defmodule Parapet.Spine.ToolAudit do
  @moduledoc """
  Ecto schema representing an audit record of a tool execution.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Parapet.Spine.TimelineEntry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_tool_audits" do
    field :tool_name, :string
    field :input, :map
    field :output, :map
    field :success, :boolean
    field :duration_ms, :integer

    belongs_to :timeline_entry, TimelineEntry, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(tool_audit, attrs) do
    tool_audit
    |> cast(attrs, [:tool_name, :input, :output, :success, :duration_ms, :timeline_entry_id])
    |> validate_required([:tool_name, :input, :success])
  end
end
