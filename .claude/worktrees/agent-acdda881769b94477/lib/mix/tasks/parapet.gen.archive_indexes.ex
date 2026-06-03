defmodule Mix.Tasks.Parapet.Gen.ArchiveIndexes do
  @moduledoc """
  Generates the Parapet migration that updates archive-related indexes and constraints.
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

    Igniter.Libs.Ecto.gen_migration(
      igniter,
      repo_module,
      "update_parapet_evidence_indexes_and_constraints",
      body: """
        def up do
          drop constraint(:parapet_tool_audits, "parapet_tool_audits_timeline_entry_id_fkey")

          alter table(:parapet_tool_audits) do
            modify :timeline_entry_id,
                   references(:parapet_timeline_entries, type: :binary_id, on_delete: :delete_all)
          end

          create index(:parapet_incidents, [:updated_at, :id], where: "state in ('open', 'investigating')")
          create index(:parapet_incidents, [:updated_at, :id], where: "state = 'resolved'")
          create index(:parapet_timeline_entries, [:incident_id, :inserted_at])
          create index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at])
        end

        def down do
          drop index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at])
          drop index(:parapet_timeline_entries, [:incident_id, :inserted_at])
          drop index(:parapet_incidents, [:updated_at, :id], where: "state = 'resolved'")
          drop index(:parapet_incidents, [:updated_at, :id], where: "state in ('open', 'investigating')")

          drop constraint(:parapet_tool_audits, "parapet_tool_audits_timeline_entry_id_fkey")

          alter table(:parapet_tool_audits) do
            modify :timeline_entry_id,
                   references(:parapet_timeline_entries, type: :binary_id, on_delete: :nilify_all)
          end
        end
      """
    )
  end
end
