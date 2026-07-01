defmodule Parapet.Repo.Migrations.AddTraceIdToIncidents do
  use Ecto.Migration

  @prefix Parapet.Spine.Schema.__prefix__()

  def change do
    alter table(:parapet_incidents, prefix: @prefix) do
      add :trace_id, :string
    end
  end
end
