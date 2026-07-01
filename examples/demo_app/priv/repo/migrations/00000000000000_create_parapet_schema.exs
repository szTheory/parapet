defmodule DemoApp.Repo.Migrations.CreateParapetSchema do
  use Ecto.Migration

  def up do
    execute("CREATE SCHEMA IF NOT EXISTS parapet")
  end

  def down do
    # Non-cascading: raises 2BP01 if any objects remain (fail-closed safety).
    # Roll back spine table migrations before rolling back this one.
    execute("DROP SCHEMA IF EXISTS parapet")
  end
end
