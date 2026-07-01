defmodule Mix.Tasks.Parapet.Gen.Schema.Move do
  @moduledoc """
  Generates a reversible single-transaction migration that moves the six Parapet
  spine tables from the `public` schema into the resolved schema prefix (Track B).

  This is an opt-in upgrade path for existing Parapet adopters who want to move
  their spine tables into a dedicated Postgres schema (e.g. `parapet`).

  ## Usage

      mix parapet.gen.schema.move
      mix parapet.gen.schema.move --schema myapp
      mix parapet.gen.schema.move --schema myapp --no-create-schema

  ## Options

  - `--schema` / `-s` — target schema name (default: `"parapet"`)
  - `--no-create-schema` — omit the `CREATE SCHEMA IF NOT EXISTS` line from the
    migration and emit a DBA least-privilege notice instead (for environments
    where the app role cannot create schemas)

  ## The emitted migration

  The generated migration (`move_parapet_spine_to_schema`) performs:

  1. `after_begin/0`: `SET LOCAL lock_timeout TO '5s'` to bound lock acquisition
     on both up and down (D-08).
  2. `up`: migrate-time abort guard (raises if any of the six spine tables is missing
     from `public`), inbound-FK/view advisory, optional `CREATE SCHEMA IF NOT EXISTS`,
     and six explicit `ALTER TABLE public.<t> SET SCHEMA <schema>` lines.
  3. `down`: six explicit reverse `ALTER TABLE <schema>.<t> SET SCHEMA public` lines
     in LIFO order. **Never `DROP SCHEMA`** (fail-closed, D-08).

  ## Second-move refusal

  If the migration module `move_parapet_spine_to_schema` already exists in your
  migrations directory, the generator refuses to emit a second migration (D-11).
  Run `mix ecto.migrate` to apply the existing migration, or delete it to regenerate.

  ## Nil / legacy leg

  If `--schema public` is given (resolved prefix is `nil`), no migration is emitted —
  the tables are already in `public`, so no move is needed.
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

    # Resolve prefix via the shared resolver — identical precedence/conflict
    # logic as gen.spine (D-06): flag > existing config > default "parapet".
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

    if is_nil(resolved) do
      # nil/legacy leg (--schema public) — emit NOTHING + zero-diff notice (D-06, Ph53 D-04).
      Igniter.add_notice(
        igniter,
        "Tables already resolve to public; no move migration needed."
      )
    else
      # Non-nil leg: emit DBA notice if --no-create-schema, then call gen_migration.
      create_schema = options[:create_schema]

      igniter
      |> Parapet.Spine.SchemaMoveNotice.emit_for_move(resolved, create_schema)
      |> Igniter.Libs.Ecto.gen_migration(
        repo_module,
        "move_parapet_spine_to_schema",
        # Do NOT pass :timestamp — a real current timestamp is required so the
        # move sorts AFTER the adopter's existing spine-table migrations (D-07, Pitfall 3).
        on_exists:
          {:error,
           "A schema-move migration already exists. Run mix ecto.migrate to " <>
             "apply it, or delete it to regenerate. Refusing to emit a second move migration."},
        body: move_migration_body(resolved, create_schema)
      )
    end
  end

  # Build the migration body string for the move migration.
  # Returns explicit up/down blocks (not change/0) plus after_begin/0 (D-08).
  defp move_migration_body(resolved, create_schema) do
    create_schema_line =
      if create_schema != false do
        ~s|    execute("CREATE SCHEMA IF NOT EXISTS #{resolved}")\n\n|
      else
        ""
      end

    """
      # after_begin/0 fires on BOTH up and down — written once, D-08 Pattern 3.
      # SET LOCAL is transaction-scoped: bounds every SET SCHEMA's ACCESS EXCLUSIVE
      # lock acquisition so a blocked move fails fast instead of queuing prod traffic.
      def after_begin do
        repo().query!("SET LOCAL lock_timeout TO '5s'")
      end

      def up do
        # -----------------------------------------------------------------------
        # Migrate-time abort guard (D-10, UPG-03):
        # Raises BEFORE any SET SCHEMA if any of the six public.<t> tables is
        # missing or renamed. Nothing moves on failure — we're inside the txn.
        # Uses to_regclass (returns NULL on absent, not an error) + quote_ident.
        # Table list is a fixed literal ARRAY, never user input (T-54-05).
        # -----------------------------------------------------------------------
        execute(\"""
        DO $$
        DECLARE t text;
        BEGIN
          FOREACH t IN ARRAY ARRAY['parapet_action_items','parapet_incidents','parapet_timeline_entries',
                                   'parapet_tool_audits','parapet_system_events','parapet_action_claims'] LOOP
            IF to_regclass('public.' || quote_ident(t)) IS NULL THEN
              RAISE EXCEPTION 'Parapet spine table public.% not found. If you renamed Parapet tables, '
                'edit this migration''s table list before migrating.', t;
            END IF;
          END LOOP;
        END $$;
        \""")

        # -----------------------------------------------------------------------
        # Non-blocking inbound FK / view advisory (D-10, UPG-03):
        # PG moves intra-spine FKs automatically; cross-schema FKs from adopter
        # tables remain valid. Only views/rules referencing spine tables by
        # unqualified name may silently rebind after the move. This is a NOTICE,
        # not an abort — the adopter reviews and re-qualifies affected views.
        # -----------------------------------------------------------------------
        execute(\"""
        DO $$
        DECLARE r record;
        BEGIN
          FOR r IN
            SELECT DISTINCT view_name
            FROM information_schema.view_table_usage
            WHERE table_schema = 'public'
              AND table_name IN ('parapet_action_items','parapet_incidents',
                                 'parapet_timeline_entries','parapet_tool_audits',
                                 'parapet_system_events','parapet_action_claims')
          LOOP
            RAISE NOTICE 'View % references a Parapet spine table being moved. '
              'Review and re-qualify its definition after this migration to avoid '
              'silent rebinding.', r.view_name;
          END LOOP;
        END $$;
        \""")

    #{create_schema_line}    # Six explicit SET SCHEMA lines (D-08, D-09):
        # NOT a for-loop — a prod PR must `grep parapet_incidents migration.exs`
        # and hit this moved line. Fully-qualified source: public.<t> (D-09).
        execute("ALTER TABLE public.parapet_action_items SET SCHEMA #{resolved}")
        execute("ALTER TABLE public.parapet_incidents SET SCHEMA #{resolved}")
        execute("ALTER TABLE public.parapet_timeline_entries SET SCHEMA #{resolved}")
        execute("ALTER TABLE public.parapet_tool_audits SET SCHEMA #{resolved}")
        execute("ALTER TABLE public.parapet_system_events SET SCHEMA #{resolved}")
        execute("ALTER TABLE public.parapet_action_claims SET SCHEMA #{resolved}")
      end

      def down do
        # Six explicit reverse SET SCHEMA lines in LIFO order (D-08, D-09).
        # Fully-qualified source: <resolved>.<t> (D-09 — never rely on search_path).
        execute("ALTER TABLE #{resolved}.parapet_action_claims SET SCHEMA public")
        execute("ALTER TABLE #{resolved}.parapet_system_events SET SCHEMA public")
        execute("ALTER TABLE #{resolved}.parapet_tool_audits SET SCHEMA public")
        execute("ALTER TABLE #{resolved}.parapet_timeline_entries SET SCHEMA public")
        execute("ALTER TABLE #{resolved}.parapet_incidents SET SCHEMA public")
        execute("ALTER TABLE #{resolved}.parapet_action_items SET SCHEMA public")
        # NOTE: Deliberately no DROP SCHEMA here (fail-closed, D-08).
        # The target schema may contain other Parapet objects (e.g. from the sentinel
        # migration). DROP SCHEMA belongs to the sentinel migration's down/0, or a DBA.
      end
    """
  end
end
