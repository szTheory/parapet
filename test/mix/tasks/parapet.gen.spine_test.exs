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

      assert migration_source =~ "create table(:parapet_incidents, primary_key: false)"
      assert migration_source =~ "create table(:parapet_timeline_entries, primary_key: false)"
      assert migration_source =~ "create table(:parapet_tool_audits, primary_key: false)"
    end
  end
end
