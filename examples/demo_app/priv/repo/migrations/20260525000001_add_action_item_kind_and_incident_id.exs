defmodule DemoApp.Repo.Migrations.AddActionItemKindAndIncidentId do
  use Ecto.Migration

  def change do
    alter table(:parapet_action_items) do
      add :kind, :string, default: "exact_follow_up", null: false
      add :incident_id, references(:parapet_incidents, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:parapet_action_items, [:incident_id])
  end
end
