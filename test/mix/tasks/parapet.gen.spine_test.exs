defmodule Mix.Tasks.Parapet.Gen.SpineTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Spine

  describe "mix parapet.gen.spine" do
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

      assert contains_snippet?(migration_ast, "create(table(:parapet_incidents, primary_key: false))")
      assert contains_snippet?(migration_ast, "create(table(:parapet_timeline_entries, primary_key: false))")
      assert contains_snippet?(migration_ast, "create(table(:parapet_tool_audits, primary_key: false))")
      assert contains_snippet?(migration_ast, "references(:parapet_timeline_entries, type: :binary_id, on_delete: :delete_all)")
      assert normalized_source =~
               "create( index(:parapet_incidents, [:updated_at, :id], where: \"state in ('open', 'investigating')\") )"

      assert normalized_source =~
               "create(index(:parapet_incidents, [:updated_at, :id], where: \"state = 'resolved'\"))"

      assert contains_snippet?(migration_ast, "create(index(:parapet_timeline_entries, [:incident_id, :inserted_at]))")
      assert contains_snippet?(migration_ast, "create(index(:parapet_tool_audits, [:timeline_entry_id, :inserted_at]))")
    end
  end

  defp contains_snippet?(ast, snippet) do
    ast
    |> Macro.to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.contains?(snippet)
  end
end
