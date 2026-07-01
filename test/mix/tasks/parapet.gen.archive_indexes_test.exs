defmodule Mix.Tasks.Parapet.Gen.ArchiveIndexesTest do
  use ExUnit.Case, async: false
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.ArchiveIndexes

  describe "mix parapet.gen.archive_indexes" do
    test "generates an upgrade migration with explicit up/down and archive indexes" do
      igniter =
        test_project(app_name: :test)
        |> ArchiveIndexes.igniter()

      migration_file =
        igniter.rewrite
        |> Rewrite.sources()
        |> Enum.map(&Rewrite.Source.get(&1, :path))
        |> Enum.find(&String.contains?(&1, "update_parapet_evidence_indexes_and_constraints.exs"))

      assert migration_file
      assert_creates(igniter, migration_file)

      migration_source =
        Rewrite.source!(igniter.rewrite, migration_file)
        |> Rewrite.Source.get(:content)

      migration_ast = Code.string_to_quoted!(migration_source)

      up_ast = find_def_ast(migration_ast, :up)
      down_ast = find_def_ast(migration_ast, :down)

      assert up_ast
      assert down_ast

      assert contains_snippet?(
               up_ast,
               "constraint(:parapet_tool_audits, \"parapet_tool_audits_timeline_entry_id_fkey\""
             )

      assert contains_snippet?(
               up_ast,
               "references(:parapet_timeline_entries, type: :binary_id, on_delete: :delete_all"
             )

      assert contains_snippet?(
               up_ast,
               "index(:parapet_incidents, [:updated_at, :id]"
             )

      assert contains_snippet?(
               down_ast,
               "constraint(:parapet_tool_audits, \"parapet_tool_audits_timeline_entry_id_fkey\""
             )

      assert contains_snippet?(
               down_ast,
               "references(:parapet_timeline_entries, type: :binary_id, on_delete: :nilify_all"
             )

      assert contains_snippet?(
               down_ast,
               "index(:parapet_incidents, [:updated_at, :id]"
             )

      assert contains_snippet?(
               down_ast,
               "index(:parapet_timeline_entries, [:incident_id, :inserted_at]"
             )

      assert contains_snippet?(
               down_ast,
               "index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at]"
             )
    end

    # GEN-02: count-guard — prefix: stamped on every create/drop index, references, and constraint
    # in BOTH up and down (Pitfall 4 — drop direction must also carry prefix).
    # Expected breakdown (parapet leg):
    #   up:   1 drop constraint + 1 alter table + 1 modify references + 4 create index = 7
    #   down: 4 drop index + 1 drop constraint + 1 alter table + 1 modify references = 7
    # Total: 14
    test "GEN-02: prefix: count-guard on both up and down in parapet leg" do
      igniter =
        test_project(app_name: :test)
        |> ArchiveIndexes.igniter()

      migration_file =
        igniter.rewrite
        |> Rewrite.sources()
        |> Enum.map(&Rewrite.Source.get(&1, :path))
        |> Enum.find(&String.contains?(&1, "update_parapet_evidence_indexes_and_constraints.exs"))

      migration_source =
        Rewrite.source!(igniter.rewrite, migration_file)
        |> Rewrite.Source.get(:content)

      prefix_count = Regex.scan(~r/\bprefix:/, migration_source) |> length()

      assert prefix_count >= 14,
             "Expected at least 14 prefix: occurrences in archive_indexes migration (up + down, Pitfall 4), got #{prefix_count}"
    end

    # GEN-07: FK constraint name unchanged in the parapet leg (D-03).
    # Ecto derives constraint names from table.name only, not prefix (connection.ex:1884-1885).
    test "GEN-02/GEN-07: FK constraint name byte-identical in parapet leg" do
      igniter =
        test_project(app_name: :test)
        |> ArchiveIndexes.igniter()

      migration_file =
        igniter.rewrite
        |> Rewrite.sources()
        |> Enum.map(&Rewrite.Source.get(&1, :path))
        |> Enum.find(&String.contains?(&1, "update_parapet_evidence_indexes_and_constraints.exs"))

      migration_source =
        Rewrite.source!(igniter.rewrite, migration_file)
        |> Rewrite.Source.get(:content)

      migration_ast = Code.string_to_quoted!(migration_source)
      up_ast = find_def_ast(migration_ast, :up)
      down_ast = find_def_ast(migration_ast, :down)

      # FK constraint name must be byte-identical regardless of prefix (D-03).
      assert contains_snippet?(
               up_ast,
               "\"parapet_tool_audits_timeline_entry_id_fkey\""
             ),
             "Expected FK constraint name 'parapet_tool_audits_timeline_entry_id_fkey' unchanged in up (D-03)"

      assert contains_snippet?(
               down_ast,
               "\"parapet_tool_audits_timeline_entry_id_fkey\""
             ),
             "Expected FK constraint name 'parapet_tool_audits_timeline_entry_id_fkey' unchanged in down (D-03)"
    end

    # GEN-02/GEN-07: FK constraint name unchanged under nil-config leg (D-03).
    # Even when schema_prefix is nil (no prefix), the constraint name stays the same.
    test "GEN-02/GEN-07: FK constraint name byte-identical in nil-config leg" do
      original = Application.get_env(:parapet, :schema_prefix)
      Application.put_env(:parapet, :schema_prefix, nil)

      igniter =
        test_project(app_name: :test)
        |> ArchiveIndexes.igniter()

      Application.put_env(:parapet, :schema_prefix, original)

      migration_file =
        igniter.rewrite
        |> Rewrite.sources()
        |> Enum.map(&Rewrite.Source.get(&1, :path))
        |> Enum.find(&String.contains?(&1, "update_parapet_evidence_indexes_and_constraints.exs"))

      migration_source =
        Rewrite.source!(igniter.rewrite, migration_file)
        |> Rewrite.Source.get(:content)

      migration_ast = Code.string_to_quoted!(migration_source)
      up_ast = find_def_ast(migration_ast, :up)
      down_ast = find_def_ast(migration_ast, :down)

      # FK constraint name must be byte-identical regardless of prefix (D-03).
      assert contains_snippet?(
               up_ast,
               "\"parapet_tool_audits_timeline_entry_id_fkey\""
             ),
             "Expected FK constraint name unchanged in up under nil-config leg (D-03)"

      assert contains_snippet?(
               down_ast,
               "\"parapet_tool_audits_timeline_entry_id_fkey\""
             ),
             "Expected FK constraint name unchanged in down under nil-config leg (D-03)"
    end

    # GEN-02: Pitfall 4 — drop index/constraint in the down direction must carry prefix:
    # so Postgres looks in the correct schema.
    test "GEN-02: down direction drop index/constraint carries prefix: (Pitfall 4)" do
      igniter =
        test_project(app_name: :test)
        |> ArchiveIndexes.igniter()

      migration_file =
        igniter.rewrite
        |> Rewrite.sources()
        |> Enum.map(&Rewrite.Source.get(&1, :path))
        |> Enum.find(&String.contains?(&1, "update_parapet_evidence_indexes_and_constraints.exs"))

      migration_source =
        Rewrite.source!(igniter.rewrite, migration_file)
        |> Rewrite.Source.get(:content)

      migration_ast = Code.string_to_quoted!(migration_source)
      down_ast = find_def_ast(migration_ast, :down)
      down_str = Macro.to_string(down_ast)

      # drop index in down should carry prefix:
      assert String.contains?(down_str, "prefix:"),
             "Expected prefix: on drop index/constraint in down direction (Pitfall 4), got: #{down_str}"
    end
  end

  defp find_def_ast(ast, name) do
    {_ast, result} =
      Macro.prewalk(ast, nil, fn
        {:def, _, [{^name, _, _}, [do: body]]} = node, _acc -> {node, body}
        node, acc -> {node, acc}
      end)

    result
  end

  defp contains_snippet?(ast, snippet) do
    ast
    |> Macro.to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.contains?(snippet)
  end
end
