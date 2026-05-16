defmodule Parapet.Repo.Migrations.AddTraceIdToIncidents do
  use Ecto.Migration

  def change do
    alter table(:parapet_incidents) do
      add :trace_id, :string
    end
  end
end
