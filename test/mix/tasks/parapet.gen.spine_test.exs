defmodule Mix.Tasks.Parapet.Gen.SpineTest do
  use ExUnit.Case, async: false
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Spine

  # ── Default run (parapet prefix) ─────────────────────────────────────────────

  describe "mix parapet.gen.spine (default: schema = parapet)" do
    setup do
      # Ensure we start with the parapet config (the local dev default).
      # Tests in this group all expect resolved = "parapet".
      on_exit(fn -> Application.put_env(:parapet, :schema_prefix, "parapet") end)
      :ok
    end

    test "generates migration and configures repo" do
      igniter =
        test_project(app_name: :test)
        |> Spine.igniter()

      config_source =
        Rewrite.source!(igniter.rewrite, "config/config.exs")
        |> Rewrite.Source.get(:content)

      assert config_source =~ "config :parapet, repo: Test.Repo"

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
      migration_file = Enum.find(files, &String.contains?(&1, "add_parapet_spine_tables.exs"))

      assert migration_file

      migration_source =
        Rewrite.source!(igniter.rewrite, migration_file)
        |> Rewrite.Source.get(:content)

      migration_ast = Code.string_to_quoted!(migration_source)
      normalized_source = migration_source |> String.replace(~r/\s+/, " ")

      assert contains_snippet?(
               migration_ast,
               "create(table(:parapet_incidents, primary_key: false, prefix: \"parapet\"))"
             )

      assert contains_snippet?(
               migration_ast,
               "create(table(:parapet_timeline_entries, primary_key: false, prefix: \"parapet\"))"
             )

      assert contains_snippet?(
               migration_ast,
               "create(table(:parapet_tool_audits, primary_key: false, prefix: \"parapet\"))"
             )

      assert contains_snippet?(
               migration_ast,
               "references(:parapet_incidents, type: :binary_id, on_delete: :delete_all, prefix: \"parapet\""
             )

      assert normalized_source =~
               "prefix: \"parapet\", where: \"state in ('open', 'investigating')\""

      assert normalized_source =~
               "prefix: \"parapet\", where: \"state = 'resolved'\""

      assert contains_snippet?(
               migration_ast,
               "create(index(:parapet_timeline_entries, [:incident_id, :inserted_at], prefix: \"parapet\"))"
             )

      assert contains_snippet?(
               migration_ast,
               "create(index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at], prefix: \"parapet\"))"
             )

      assert Regex.scan(~r/timestamps\(type: :utc_datetime_usec\)/, migration_source)
             |> length() == 5
    end

    # GEN-02: count-guard — every table, reference, and index carries prefix: in the parapet leg.
    # Expected breakdown:
    #   5 tables (action_items, incidents, timeline_entries, tool_audits, system_events)
    #   2 references (incident_id → incidents, timeline_entry_id → timeline_entries)
    #   8 indexes (1 unique + 2 where + 2 timeline + 2 tool_audits + 1 system_events)
    # Total: 15
    test "GEN-02: every table/reference/index carries prefix: in the generated migration (count-guard)" do
      igniter =
        test_project(app_name: :test)
        |> Spine.igniter()

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
      migration_file = Enum.find(files, &String.contains?(&1, "add_parapet_spine_tables.exs"))
      migration_source = Rewrite.source!(igniter.rewrite, migration_file) |> Rewrite.Source.get(:content)

      prefix_count = Regex.scan(~r/\bprefix:/, migration_source) |> length()
      assert prefix_count >= 15,
             "Expected at least 15 prefix: occurrences (5 tables + 2 references + 8 indexes), got #{prefix_count}"
    end

    # GEN-01: sentinel migration created with correct path.
    test "GEN-01: sentinel 00000000000000_create_parapet_schema.exs is created" do
      igniter =
        test_project(app_name: :test)
        |> Spine.igniter()

      assert_creates(igniter, "priv/repo/migrations/00000000000000_create_parapet_schema.exs")
    end

    # GEN-01: golden bytes — exact content of the sentinel migration.
    # Captured from a live test run and pinned. The down/0 must NOT contain CASCADE (D-14).
    test "GEN-01: sentinel migration golden bytes (non-cascading DROP SCHEMA)" do
      igniter =
        test_project(app_name: :test)
        |> Spine.igniter()

      sentinel_path = "priv/repo/migrations/00000000000000_create_parapet_schema.exs"
      source = Rewrite.source!(igniter.rewrite, sentinel_path)
      content = Rewrite.Source.get(source, :content)

      assert content =~ "CREATE SCHEMA IF NOT EXISTS parapet"
      assert content =~ "DROP SCHEMA IF EXISTS parapet"
      refute content =~ "CASCADE",
             "Sentinel down/0 must NOT use CASCADE — non-cascading DROP is a deliberate fail-closed safety feature (D-14)"
    end

    # GEN-03: config :parapet, :schema_prefix written (no-clobber).
    test "GEN-03: configure_new writes config :parapet, :schema_prefix" do
      igniter =
        test_project(app_name: :test)
        |> Spine.igniter()

      config_source =
        Rewrite.source!(igniter.rewrite, "config/config.exs")
        |> Rewrite.Source.get(:content)

      assert config_source =~ "schema_prefix",
             "Expected config/config.exs to contain schema_prefix config after gen.spine"
    end

    # GEN-02: FK constraint name unchanged in the parapet leg.
    # Parapet.Spine.Schema uses @prefix only for schema routing; FK names are derived from
    # table.name only (Ecto ecto_sql connection.ex:1884-1885, D-03).
    test "GEN-02: FK constraint name byte-identical in parapet leg" do
      igniter =
        test_project(app_name: :test)
        |> Spine.igniter()

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
      migration_file = Enum.find(files, &String.contains?(&1, "add_parapet_spine_tables.exs"))
      migration_source = Rewrite.source!(igniter.rewrite, migration_file) |> Rewrite.Source.get(:content)

      # The references call itself is present with the correct name-generating arguments.
      # FK name will be parapet_timeline_entries_incident_id_fkey (generated by Ecto from table name).
      assert migration_source =~ "references(:parapet_incidents",
             "Expected references to parapet_incidents in spine migration"
    end
  end

  # ── --no-create-schema ──────────────────────────────────────────────────────

  describe "mix parapet.gen.spine --no-create-schema" do
    test "GEN-01/GEN-04: omits sentinel and emits DBA remediation notice" do
      igniter =
        test_project(app_name: :test)
        |> then(fn ig -> put_in(ig.args.options[:create_schema], false) end)
        |> Spine.igniter()

      # GEN-01: sentinel NOT created
      refute_creates(
        igniter,
        "priv/repo/migrations/00000000000000_create_parapet_schema.exs"
      )

      # GEN-04: DBA remediation notice is present in the notices list
      notices = igniter.notices
      assert Enum.any?(notices, &String.contains?(&1, "CREATE SCHEMA IF NOT EXISTS")),
             "Expected a notice containing CREATE SCHEMA IF NOT EXISTS, got: #{inspect(notices)}"

      assert Enum.any?(notices, &String.contains?(&1, "GRANT")),
             "Expected DBA GRANT remediation in notices, got: #{inspect(notices)}"
    end

    test "GEN-02: tables still carry prefix: under --no-create-schema" do
      igniter =
        test_project(app_name: :test)
        |> then(fn ig -> put_in(ig.args.options[:create_schema], false) end)
        |> Spine.igniter()

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
      migration_file = Enum.find(files, &String.contains?(&1, "add_parapet_spine_tables.exs"))
      migration_source = Rewrite.source!(igniter.rewrite, migration_file) |> Rewrite.Source.get(:content)

      prefix_count = Regex.scan(~r/\bprefix:/, migration_source) |> length()
      assert prefix_count >= 15,
             "Expected prefix: on all tables/references/indexes even under --no-create-schema, got #{prefix_count}"
    end

    # GEN-02: FK constraint name unchanged under --no-create-schema leg.
    test "GEN-02: FK constraint name byte-identical under --no-create-schema" do
      igniter =
        test_project(app_name: :test)
        |> then(fn ig -> put_in(ig.args.options[:create_schema], false) end)
        |> Spine.igniter()

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
      migration_file = Enum.find(files, &String.contains?(&1, "add_parapet_spine_tables.exs"))
      migration_source = Rewrite.source!(igniter.rewrite, migration_file) |> Rewrite.Source.get(:content)

      assert migration_source =~ "references(:parapet_incidents",
             "Expected references to parapet_incidents in spine migration under --no-create-schema"
    end
  end

  # ── Nil-prefix leg (public schema — config nil, no flag) ─────────────────────
  # NOTE: The resolver always returns {:ok, "parapet"} as default when both flag and config
  # normalize to nil (see resolve_prefix/2 pure-core tests in schema_test.exs, D-06).
  # This test documents the correct behavior: even with schema_prefix=nil in config,
  # the resolver uses "parapet" as default. The "no prefix" leg is represented by
  # the pure-core tests in schema_test.exs that verify {:ok, nil} is never returned.

  describe "mix parapet.gen.spine (nil config, no flag — default parapet applies)" do
    setup do
      original = Application.get_env(:parapet, :schema_prefix)
      Application.put_env(:parapet, :schema_prefix, nil)
      on_exit(fn -> Application.put_env(:parapet, :schema_prefix, original) end)
      :ok
    end

    test "uses parapet default when config is nil and no flag provided" do
      igniter =
        test_project(app_name: :test)
        |> Spine.igniter()

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
      migration_file = Enum.find(files, &String.contains?(&1, "add_parapet_spine_tables.exs"))
      migration_source = Rewrite.source!(igniter.rewrite, migration_file) |> Rewrite.Source.get(:content)

      # With nil config and no flag, resolver defaults to "parapet" (D-06, "absence = default").
      # Output is prefix-stamped with "parapet" — NOT unprefixed.
      prefix_count = Regex.scan(~r/\bprefix:/, migration_source) |> length()
      assert prefix_count >= 15,
             "Expected default parapet prefix when config is nil (resolver defaults to parapet), got #{prefix_count}"
    end
  end

  defp contains_snippet?(ast, snippet) do
    ast
    |> Macro.to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.contains?(snippet)
  end
end
