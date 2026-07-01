defmodule Parapet.Repo.Migrations.AddRunbookDataToIncidents do
  use Ecto.Migration

  @prefix Parapet.Spine.Schema.__prefix__()

  def change do
    alter table(:parapet_incidents, prefix: @prefix) do
      add :runbook_data, :map
    end
  end
end
