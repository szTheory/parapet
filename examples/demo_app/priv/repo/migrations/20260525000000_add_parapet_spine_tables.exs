defmodule DemoApp.Repo.Migrations.AddParapetSpineTables do
  use Ecto.Migration

  def change do
    create table(:parapet_action_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :integration, :string, null: false
      add :external_id, :string, null: false
      add :state, :string, default: "open", null: false

      timestamps()
    end

    create table(:parapet_incidents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :state, :string, default: "open", null: false
      add :title, :string, null: false
      add :description, :text
      add :correlation_key, :string
      add :runbook_data, :map
      add :trace_id, :string

      timestamps()
    end

    create unique_index(:parapet_incidents, [:correlation_key], where: "state = 'open'")
    create index(:parapet_incidents, [:updated_at, :id],
      where: "state in ('open', 'investigating')",
      name: :parapet_incidents_queue_cursor_index
    )
    create index(:parapet_incidents, [:updated_at, :id],
      where: "state = 'resolved'",
      name: :parapet_incidents_history_cursor_index
    )

    create table(:parapet_timeline_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :payload, :map, default: %{}
      add :incident_id, references(:parapet_incidents, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:parapet_timeline_entries, [:incident_id])
    create index(:parapet_timeline_entries, [:incident_id, :inserted_at])

    create table(:parapet_tool_audits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tool_name, :string, null: false
      add :input, :map, default: %{}
      add :output, :map, default: %{}
      add :success, :boolean, default: false, null: false
      add :duration_ms, :integer
      add :timeline_entry_id, references(:parapet_timeline_entries, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create index(:parapet_tool_audits, [:timeline_entry_id])
    create index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at])

    create table(:parapet_system_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :payload, :map, default: %{}

      timestamps()
    end

    create index(:parapet_system_events, [:inserted_at])
  end
end
