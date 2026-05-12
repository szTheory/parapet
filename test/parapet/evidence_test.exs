defmodule Parapet.EvidenceTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset) do
      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      else
        {:error, changeset}
      end
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    on_exit(fn -> Application.delete_env(:parapet, :repo) end)
    :ok
  end

  describe "repo/0" do
    test "fetches repo from application env" do
      assert Parapet.Evidence.repo() == DummyRepo
    end

    test "raises a clear error when repo is not configured" do
      Application.delete_env(:parapet, :repo)

      assert_raise ArgumentError, ~r/requires a :repo to be configured/, fn ->
        Parapet.Evidence.repo()
      end
    end
  end

  describe "create_incident/1" do
    test "creates an incident with valid attrs" do
      attrs = %{title: "API Outage", description: "Database is slow"}
      assert {:ok, incident} = Parapet.Evidence.create_incident(attrs)
      assert incident.title == "API Outage"
      assert incident.state == "open"
    end

    test "returns error changeset for invalid attrs" do
      attrs = %{title: nil}
      assert {:error, changeset} = Parapet.Evidence.create_incident(attrs)
      refute changeset.valid?
    end
  end

  describe "append_timeline/2" do
    test "appends a timeline entry" do
      incident_id = Ecto.UUID.generate()
      attrs = %{type: "note", payload: %{"text" => "Looked into it"}}
      assert {:ok, entry} = Parapet.Evidence.append_timeline(incident_id, attrs)
      assert entry.incident_id == incident_id
      assert entry.type == "note"
    end
  end

  describe "log_tool_audit/1" do
    test "logs a tool audit" do
      attrs = %{tool_name: "test_tool", input: %{"a" => 1}, success: true}
      assert {:ok, audit} = Parapet.Evidence.log_tool_audit(attrs)
      assert audit.tool_name == "test_tool"
    end
  end
end
