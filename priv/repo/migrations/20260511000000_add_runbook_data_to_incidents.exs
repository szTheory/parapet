defmodule Parapet.Repo.Migrations.AddRunbookDataToIncidents do
  use Ecto.Migration

  def change do
    alter table(:parapet_incidents) do
      add :runbook_data, :map
    end
  end
end
