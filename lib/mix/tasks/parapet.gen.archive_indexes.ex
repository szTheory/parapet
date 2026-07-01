defmodule Mix.Tasks.Parapet.Gen.ArchiveIndexes do
  @moduledoc """
  Generates the Parapet migration that updates archive-related indexes and constraints.

  ## Schema prefix

  Pass `--schema <name>` (or `-s <name>`) to stamp the generated migration with the given
  Postgres schema prefix. The resolved prefix is applied to every `create index`, `drop index`,
  `references/2`, and `drop constraint` call in both the `up/0` and `down/0` bodies.

  FK constraint names (e.g. `parapet_tool_audits_timeline_entry_id_fkey`) are byte-identical
  regardless of whether a prefix is applied — Ecto derives constraint names from the table name
  only, not the schema prefix (D-03).

  ## Nil / legacy leg

  If the resolved schema prefix is `nil` (e.g. `--schema public`), no `prefix:` option is
  emitted — output is byte-for-byte the pre-v1.7 baseline.

  ## Note on --no-create-schema

  This generator does NOT emit the schema sentinel migration — that is `gen.spine`'s
  responsibility. The `--no-create-schema` flag is accepted (for composed-task routing via
  `group: :parapet`) but has no effect here beyond flag routing.
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [
        schema: :string,
        create_schema: :boolean
      ],
      defaults: [
        schema: "parapet",
        create_schema: true
      ],
      aliases: [s: :schema],
      group: :parapet
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_module = Igniter.Project.Module.module_name_prefix(igniter)
    repo_module = Module.concat([app_module, Repo])

    # Resolve prefix via the shared resolver (GEN-05, D-05, D-06).
    # Precedence: flag > existing config > default "parapet".
    {igniter, resolved} =
      case Parapet.Spine.Schema.resolve_prefix(igniter) do
        {:ok, prefix} ->
          {igniter, prefix}

        {:conflict, flag_prefix, config_prefix} ->
          warned =
            Igniter.add_warning(
              igniter,
              "--schema #{inspect(flag_prefix)} conflicts with config :parapet, :schema_prefix " <>
                "#{inspect(config_prefix)}. " <>
                "The flag value will be used for this run. To reconcile, update config/config.exs " <>
                "and run: mix deps.compile parapet --force"
            )

          {warned, flag_prefix}
      end

    # Build a generate-time prefix fragment (D-01, D-04, Pitfall 6).
    # When resolved is nil (e.g. --schema public), emit NO prefix: opt — zero-diff to current
    # output (D-04). Never emit prefix: nil — that would appear literally in the heredoc.
    prefix_opts = if resolved, do: ", prefix: #{inspect(resolved)}", else: ""

    # For standalone index/constraint calls with NO other options:
    prefix_index_only = if resolved, do: ", prefix: #{inspect(resolved)}", else: ""

    # For standalone index calls that also have a `where:` option (prefix comes first):
    prefix_index_lead = if resolved, do: "prefix: #{inspect(resolved)}, ", else: ""

    Igniter.Libs.Ecto.gen_migration(
      igniter,
      repo_module,
      "update_parapet_evidence_indexes_and_constraints",
      body: """
        def up do
          drop constraint(:parapet_tool_audits, "parapet_tool_audits_timeline_entry_id_fkey"#{prefix_index_only})

          alter table(:parapet_tool_audits#{prefix_opts}) do
            modify :timeline_entry_id,
                   references(:parapet_timeline_entries, type: :binary_id, on_delete: :delete_all#{prefix_opts})
          end

          create index(:parapet_incidents, [:updated_at, :id], #{prefix_index_lead}where: "state in ('open', 'investigating')")
          create index(:parapet_incidents, [:updated_at, :id], #{prefix_index_lead}where: "state = 'resolved'")
          create index(:parapet_timeline_entries, [:incident_id, :inserted_at]#{prefix_index_only})
          create index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at]#{prefix_index_only})
        end

        def down do
          drop index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at]#{prefix_index_only})
          drop index(:parapet_timeline_entries, [:incident_id, :inserted_at]#{prefix_index_only})
          drop index(:parapet_incidents, [:updated_at, :id], #{prefix_index_lead}where: "state = 'resolved'")
          drop index(:parapet_incidents, [:updated_at, :id], #{prefix_index_lead}where: "state in ('open', 'investigating')")

          drop constraint(:parapet_tool_audits, "parapet_tool_audits_timeline_entry_id_fkey"#{prefix_index_only})

          alter table(:parapet_tool_audits#{prefix_opts}) do
            modify :timeline_entry_id,
                   references(:parapet_timeline_entries, type: :binary_id, on_delete: :nilify_all#{prefix_opts})
          end
        end
      """
    )
  end
end
