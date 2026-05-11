defmodule Mix.Tasks.Parapet.Gen.Spine do
  @moduledoc """
  Installs the Parapet Evidence Spine by generating migrations and configuring the host Ecto Repo.
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{}
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_module = Igniter.Project.Module.module_name_prefix(igniter)
    repo_module = Module.concat([app_module, Repo])

    igniter
    |> Igniter.Project.Config.configure(
      "config.exs",
      :parapet,
      [:repo],
      repo_module
    )
    |> Igniter.Libs.Ecto.gen_migration(repo_module, "add_parapet_spine_tables",
      body: """
        def change do
          create table(:parapet_incidents, primary_key: false) do
            add :id, :binary_id, primary_key: true
            add :state, :string, default: "open", null: false
            add :title, :string, null: false
            add :description, :text

            timestamps()
          end

          create table(:parapet_timeline_entries, primary_key: false) do
            add :id, :binary_id, primary_key: true
            add :type, :string, null: false
            add :payload, :map, default: %{}
            add :incident_id, references(:parapet_incidents, type: :binary_id, on_delete: :delete_all), null: false

            timestamps()
          end

          create index(:parapet_timeline_entries, [:incident_id])

          create table(:parapet_tool_audits, primary_key: false) do
            add :id, :binary_id, primary_key: true
            add :tool_name, :string, null: false
            add :input, :map, default: %{}
            add :output, :map, default: %{}
            add :success, :boolean, default: false, null: false
            add :duration_ms, :integer
            add :timeline_entry_id, references(:parapet_timeline_entries, type: :binary_id, on_delete: :nilify_all)

            timestamps()
          end

          create index(:parapet_tool_audits, [:timeline_entry_id])
        end
      """
    )
  end
end
