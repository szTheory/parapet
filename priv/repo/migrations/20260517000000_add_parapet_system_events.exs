defmodule Parapet.Repo.Migrations.AddParapetSystemEvents do
  use Ecto.Migration

  @prefix Parapet.Spine.Schema.__prefix__()

  def change do
    create table(:parapet_system_events, primary_key: false, prefix: @prefix) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :payload, :map, default: %{}

      timestamps()
    end

    create index(:parapet_system_events, [:inserted_at], prefix: @prefix)
  end
end
