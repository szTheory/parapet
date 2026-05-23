defmodule Parapet.Repo.Migrations.CreateParapetActionClaims do
  use Ecto.Migration

  def change do
    create table(:parapet_action_claims, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :incident_id, references(:parapet_incidents, type: :binary_id, on_delete: :delete_all),
        null: false

      add :action_kind, :string, null: false
      add :action_key, :string, null: false
      add :status, :string, null: false, default: "claimed"
      add :idempotency_key, :string, null: false
      add :attempt_count, :integer, null: false, default: 1
      add :claimed_at, :utc_datetime_usec, null: false
      add :finished_at, :utc_datetime_usec
      add :short_circuit_reason, :string
      add :last_error_kind, :string
      add :last_error_message, :text
      add :error_metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:parapet_action_claims, [:incident_id, :action_kind, :action_key])
    create index(:parapet_action_claims, [:status, :claimed_at])
    create index(:parapet_action_claims, [:incident_id, :inserted_at])
  end
end
