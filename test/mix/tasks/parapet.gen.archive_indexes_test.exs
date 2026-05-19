defmodule Mix.Tasks.Parapet.Gen.ArchiveIndexesTest do
  use ExUnit.Case, async: true
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
               "drop(constraint(:parapet_tool_audits, \"parapet_tool_audits_timeline_entry_id_fkey\"))"
             )
      assert contains_snippet?(
               up_ast,
               "references(:parapet_timeline_entries, type: :binary_id, on_delete: :delete_all)"
             )
      assert contains_snippet?(up_ast, "create(index(:parapet_incidents, [:state, :inserted_at]))")
      assert contains_snippet?(up_ast, "create(index(:parapet_timeline_entries, [:incident_id, :inserted_at]))")
      assert contains_snippet?(up_ast, "create(index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at]))")

      assert contains_snippet?(
               down_ast,
               "drop(constraint(:parapet_tool_audits, \"parapet_tool_audits_timeline_entry_id_fkey\"))"
             )
      assert contains_snippet?(
               down_ast,
               "references(:parapet_timeline_entries, type: :binary_id, on_delete: :nilify_all)"
             )
      assert contains_snippet?(down_ast, "drop(index(:parapet_incidents, [:state, :inserted_at]))")
      assert contains_snippet?(down_ast, "drop(index(:parapet_timeline_entries, [:incident_id, :inserted_at]))")
      assert contains_snippet?(down_ast, "drop(index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at]))")
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
