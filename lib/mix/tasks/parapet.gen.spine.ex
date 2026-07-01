defmodule Mix.Tasks.Parapet.Gen.Spine do
  @moduledoc """
  Installs the Parapet Evidence Spine by generating migrations and configuring the host Ecto Repo.

  ## Schema prefix

  By default, all Parapet tables are created in the `parapet` Postgres schema. A first-ordered
  sentinel migration (`00000000000000_create_parapet_schema.exs`) is generated to create that
  schema before any table migrations run.

  Pass `--schema <name>` (or `-s <name>`) to use a custom schema name. Pass `--no-create-schema`
  to skip the sentinel migration and instead receive a DBA remediation notice with the SQL to run
  once as a privileged role.

  ## Nil / legacy leg

  If the resolved schema prefix is `nil` (e.g. `--schema public`), no `prefix:` option is
  emitted on any table, reference, or index — output is byte-for-byte the pre-v1.7 baseline.

  ## Sentinel migration note

  The sentinel `00000000000000_create_parapet_schema.exs` uses Ecto migrator version `0`,
  which sorts strictly before every real timestamp. Its `down/0` uses a non-cascading
  `DROP SCHEMA IF EXISTS` — this is a deliberate fail-closed safety feature that prevents
  accidental data loss. Roll back all spine table migrations before running `mix ecto.rollback`
  to this point.

  **Parapet-vs-Parapet collision:** If an adopter runs both this generator and a future Parapet
  release that also emits a `00000000000000_create_parapet_schema.exs`, the `on_exists: :skip`
  option on `gen_migration/4` makes the second call a no-op — the existing file is kept as-is.
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
    options = igniter.args.options

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

    # Build a generate-time prefix fragment (D-01, D-04).
    # When resolved is nil (e.g. --schema public), emit NO prefix: opt — zero-diff to current
    # output (D-04). Never emit prefix: nil — that would appear literally in the heredoc.
    prefix_opts = if resolved, do: ", prefix: #{inspect(resolved)}", else: ""

    # For standalone index / unique_index calls that also have a `where:` option:
    # The prefix comes BEFORE the where clause (standard Elixir keyword list order).
    prefix_index_lead = if resolved, do: "prefix: #{inspect(resolved)}, ", else: ""

    # For standalone index calls with NO other options (2-arg form when nil, 3-arg when prefixed).
    prefix_index_only =
      if resolved, do: ", prefix: #{inspect(resolved)}", else: ""

    igniter
    |> Igniter.Project.Config.configure(
      "config.exs",
      :parapet,
      [:repo],
      repo_module
    )
    |> maybe_write_schema_prefix_config(resolved)
    |> maybe_emit_sentinel(repo_module, resolved, options[:create_schema])
    |> maybe_emit_dba_notice(resolved, options[:create_schema])
    |> Igniter.Libs.Ecto.gen_migration(repo_module, "add_parapet_spine_tables",
      body: """
        def change do
          create table(:parapet_action_items, primary_key: false#{prefix_opts}) do
            add :id, :binary_id, primary_key: true
            add :title, :string, null: false
            add :integration, :string, null: false
            add :external_id, :string, null: false
            add :state, :string, default: "open", null: false

            timestamps(type: :utc_datetime_usec)
          end

          create table(:parapet_incidents, primary_key: false#{prefix_opts}) do
            add :id, :binary_id, primary_key: true
            add :state, :string, default: "open", null: false
            add :title, :string, null: false
            add :description, :text
            add :correlation_key, :string

            timestamps(type: :utc_datetime_usec)
          end

          create unique_index(:parapet_incidents, [:correlation_key], #{prefix_index_lead}where: "state = 'open'")
          create index(:parapet_incidents, [:updated_at, :id], #{prefix_index_lead}where: "state in ('open', 'investigating')")
          create index(:parapet_incidents, [:updated_at, :id], #{prefix_index_lead}where: "state = 'resolved'")

          create table(:parapet_timeline_entries, primary_key: false#{prefix_opts}) do
            add :id, :binary_id, primary_key: true
            add :type, :string, null: false
            add :payload, :map, default: %{}
            add :incident_id, references(:parapet_incidents, type: :binary_id, on_delete: :delete_all#{prefix_opts}), null: false

            timestamps(type: :utc_datetime_usec)
          end

          create index(:parapet_timeline_entries, [:incident_id]#{prefix_index_only})
          create index(:parapet_timeline_entries, [:incident_id, :inserted_at]#{prefix_index_only})

          create table(:parapet_tool_audits, primary_key: false#{prefix_opts}) do
            add :id, :binary_id, primary_key: true
            add :tool_name, :string, null: false
            add :input, :map, default: %{}
            add :output, :map, default: %{}
            add :success, :boolean, default: false, null: false
            add :duration_ms, :integer
            add :timeline_entry_id, references(:parapet_timeline_entries, type: :binary_id, on_delete: :delete_all#{prefix_opts})

            timestamps(type: :utc_datetime_usec)
          end

          create index(:parapet_tool_audits, [:timeline_entry_id]#{prefix_index_only})
          create index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at]#{prefix_index_only})

          create table(:parapet_system_events, primary_key: false#{prefix_opts}) do
            add :id, :binary_id, primary_key: true
            add :type, :string, null: false
            add :payload, :map, default: %{}

            timestamps(type: :utc_datetime_usec)
          end

          create index(:parapet_system_events, [:inserted_at]#{prefix_index_only})
        end
      """
    )
  end

  # Persist the resolved prefix via configure_new/6 (no-clobber, GEN-03/D-07).
  # Only writes when resolved is non-nil; never overwrites an operator's hand-set value.
  defp maybe_write_schema_prefix_config(igniter, nil), do: igniter

  defp maybe_write_schema_prefix_config(igniter, resolved) do
    Igniter.Project.Config.configure_new(
      igniter,
      "config.exs",
      :parapet,
      [:schema_prefix],
      resolved
    )
  end

  # Emit the first-ordered sentinel schema migration (GEN-01, D-13, D-14).
  # Skipped when create_schema is false OR when resolved is nil.
  # nil means "default not explicitly set" — treat as true (create_schema default).
  defp maybe_emit_sentinel(igniter, _repo_module, nil, _create_schema), do: igniter
  defp maybe_emit_sentinel(igniter, _repo_module, _resolved, false), do: igniter

  defp maybe_emit_sentinel(igniter, repo_module, resolved, _create_schema) do
    Igniter.Libs.Ecto.gen_migration(
      igniter,
      repo_module,
      "create_parapet_schema",
      timestamp: "00000000000000",
      on_exists: :skip,
      body: """
        def up do
          execute("CREATE SCHEMA IF NOT EXISTS #{resolved}")
        end

        def down do
          execute("DROP SCHEMA IF EXISTS #{resolved}")
        end
      """
    )
  end

  # Emit the DBA remediation notice under --no-create-schema (GEN-04, D-15, D-12b).
  # Only emits when create_schema is false AND resolved is non-nil.
  # nil means "default not explicitly set" — treat as true (create_schema default).
  # Delegates to the shared single-source helper (Parapet.Spine.SchemaMoveNotice)
  # so the SQL body is not duplicated between gen.spine and gen.schema.move.
  defp maybe_emit_dba_notice(igniter, resolved, create_schema),
    do: Parapet.Spine.SchemaMoveNotice.emit_for_spine(igniter, resolved, create_schema)
end
