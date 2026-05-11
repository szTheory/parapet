defmodule Parapet.Spine.ToolAuditTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.ToolAudit

  describe "schema" do
    test "has expected fields" do
      assert Map.has_key?(%ToolAudit{}, :tool_name)
      assert Map.has_key?(%ToolAudit{}, :input)
      assert Map.has_key?(%ToolAudit{}, :output)
      assert Map.has_key?(%ToolAudit{}, :success)
      assert Map.has_key?(%ToolAudit{}, :duration_ms)
      assert Map.has_key?(%ToolAudit{}, :timeline_entry_id)
      assert %ToolAudit{}.__struct__.__schema__(:association, :timeline_entry)
    end
  end

  describe "changeset/2" do
    test "requires tool_name, input, success" do
      changeset = ToolAudit.changeset(%ToolAudit{}, %{})
      assert %{
               tool_name: ["can't be blank"],
               input: ["can't be blank"],
               success: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "valid with required fields" do
      changeset = ToolAudit.changeset(%ToolAudit{}, %{
        tool_name: "run_shell_command",
        input: %{"command" => "ls -la"},
        success: true
      })
      assert changeset.valid?
    end
  end

  # Helper to parse errors
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
