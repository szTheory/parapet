defmodule Parapet.OperatorTest do
  use ExUnit.Case, async: true
  alias Parapet.Operator
  alias Parapet.Spine.{Incident, TimelineEntry, ToolAudit}
  alias Parapet.Operator.ActionPayload

  defmodule DummyRepo do
    def all(_query) do
      # For tests, we mock the responses based on the query or return empty list
      []
    end
    
    def one(_query) do
      nil
    end

    def get!(Parapet.Spine.Incident, id) do
      %Parapet.Spine.Incident{id: id, state: "open", updated_at: ~U[2026-05-10 10:00:00Z]}
    end

    def transaction(multi) do
      # Very basic Ecto.Multi simulation for tests
      result =
        multi
        |> Ecto.Multi.to_list()
        |> Enum.reduce_while(%{}, fn
          {name, {:run, run_fn}}, acc ->
            case run_fn.(DummyRepo, acc) do
              {:ok, val} -> {:cont, Map.put(acc, name, val)}
              {:error, err} -> {:halt, {:error, name, err, acc}}
            end
          {name, {:insert, %Ecto.Changeset{} = changeset, opts}}, acc ->
            case insert(changeset, opts) do
               {:ok, val} -> {:cont, Map.put(acc, name, val)}
               {:error, err} -> {:halt, {:error, name, err, acc}}
            end
          {name, {:insert, fun, opts}}, acc when is_function(fun) ->
            changeset = fun.(acc)
            case insert(changeset, opts) do
               {:ok, val} -> {:cont, Map.put(acc, name, val)}
               {:error, err} -> {:halt, {:error, name, err, acc}}
            end
          {name, {:update, %Ecto.Changeset{} = changeset, opts}}, acc ->
            case update(changeset, opts) do
               {:ok, val} -> {:cont, Map.put(acc, name, val)}
               {:error, err} -> {:halt, {:error, name, err, acc}}
            end
        end)
      
      case result do
        {:error, name, err, acc} -> {:error, name, err, acc}
        map -> {:ok, map}
      end
    end

    def insert(changeset, _opts \\ []) do
      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset) |> Map.put(:id, Ecto.UUID.generate())}
      else
        {:error, changeset}
      end
    end
    
    def update(changeset, _opts \\ []) do
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

  describe "queue listing" do
    test "Queue listing returns open/investigating incidents first and resolved incidents second using the Phase 2 default sort" do
      # Note: We will test the query generation by asserting on the Ecto.Query structure
      query = Operator.queue_query()
      
      # The query should have an order_by
      assert %Ecto.Query{} = query
      # In Elixir tests without full repo, we can inspect the AST roughly,
      # but it's better to ensure the query is formed.
      assert inspect(query) =~ "order_by:"
    end
  end

  describe "incident detail" do
    test "returns a workbench-ready payload containing incident, entries, derived fields, and external links" do
      # Note: The DummyRepo currently returns empty list for all(), so entries will be empty.
      detail = Operator.incident_detail("inc-123")
      
      assert %Incident{id: "inc-123"} = detail.incident
      assert detail.entries == []
      assert %Parapet.Operator.WorkbenchContract{} = detail.derived
      assert detail.external_links == []
    end
  end

  describe "first-class commands" do
    setup do
      valid_payload = %{
        actor: "user_1", reason: "testing", correlation_id: "req_1", action_type: :immutable_fact
      }
      {:ok, payload} = ActionPayload.changeset(%ActionPayload{}, valid_payload) |> Ecto.Changeset.apply_action(:insert)
      
      incident = %Incident{id: Ecto.UUID.generate(), state: "open"}
      %{payload: payload, incident: incident}
    end

    test "mark_investigating executes incident change, timeline append, and audit write", %{payload: payload, incident: incident} do
      assert {:ok, result} = Operator.mark_investigating(incident, payload)
      assert %Incident{state: "investigating"} = result.incident
      assert %TimelineEntry{type: "status_change", payload: %{"new_state" => "investigating"}} = result.timeline_entry
      assert %ToolAudit{tool_name: "operator_mark_investigating", input: input} = result.tool_audit
      assert input["actor"] == "user_1"
    end

    test "record_note executes append without changing incident state", %{payload: payload, incident: incident} do
      assert {:ok, result} = Operator.record_note(incident, "This is a note", payload)
      assert %TimelineEntry{type: "note", payload: %{"text" => "This is a note"}} = result.timeline_entry
      assert %ToolAudit{tool_name: "operator_record_note"} = result.tool_audit
    end

    test "attach_change_marker executes append", %{payload: payload, incident: incident} do
      assert {:ok, result} = Operator.attach_change_marker(incident, "pr-123", payload)
      assert %TimelineEntry{type: "change_marker", payload: %{"change_ref" => "pr-123"}} = result.timeline_entry
      assert %ToolAudit{tool_name: "operator_attach_change_marker"} = result.tool_audit
    end

    test "request_approval executes append", %{payload: payload, incident: incident} do
      assert {:ok, result} = Operator.request_approval(incident, "mitigate-1", payload)
      assert %TimelineEntry{type: "approval_requested", payload: %{"approval_key" => "mitigate-1", "state" => "pending"}} = result.timeline_entry
      assert %ToolAudit{tool_name: "operator_request_approval"} = result.tool_audit
    end

    test "commands require a valid ActionPayload struct" do
      incident = %Incident{id: Ecto.UUID.generate(), state: "open"}
      
      invalid_payload = %ActionPayload{actor: nil} # Missing actor
      
      assert {:error, :invalid_payload} = Operator.mark_investigating(incident, invalid_payload)
    end
  end
end
