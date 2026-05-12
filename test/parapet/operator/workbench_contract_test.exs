defmodule Parapet.Operator.WorkbenchContractTest do
  use ExUnit.Case, async: false

  alias Parapet.Operator.WorkbenchContract
  alias Parapet.Evidence

  defmodule DummyRepo do
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
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    on_exit(fn -> Application.delete_env(:parapet, :repo) end)
    :ok
  end

  describe "derivation" do
    test "Workbench derivation builds queue/detail fields from explicit timeline and audit conventions" do
      incident = %Parapet.Spine.Incident{id: "inc-1", state: "open", updated_at: ~U[2026-05-10 10:00:00Z]}
      entries = []
      
      derived = WorkbenchContract.derive(incident, entries)
      assert derived.severity == nil
      assert derived.affected_journey == nil
      assert derived.resolved_at == nil
      assert derived.approval_state == :none
      assert derived.recommendation_state == :none
    end

    test "Severity and affected journey come from the latest summary/triage payload" do
      incident = %Parapet.Spine.Incident{id: "inc-1"}
      entries = [
        %Parapet.Spine.TimelineEntry{
          type: "triage_snapshot",
          payload: %{"severity" => "high", "affected_journey" => "checkout"},
          inserted_at: ~U[2026-05-10 10:00:00Z]
        },
        %Parapet.Spine.TimelineEntry{
          type: "incident_summary",
          payload: %{"severity" => "critical", "affected_journey" => "payment"},
          inserted_at: ~U[2026-05-10 10:05:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)
      assert derived.severity == "critical"
      assert derived.affected_journey == "payment"
    end

    test "correlated change comes from the latest change-marker payload, resolved ordering comes from latest resolution event timestamp" do
      incident = %Parapet.Spine.Incident{id: "inc-1", updated_at: ~U[2026-05-10 09:00:00Z]}
      entries = [
        %Parapet.Spine.TimelineEntry{
          type: "change_marker",
          payload: %{"change_ref" => "pr-123"},
          inserted_at: ~U[2026-05-10 10:00:00Z]
        },
        %Parapet.Spine.TimelineEntry{
          type: "incident_resolved",
          payload: %{},
          inserted_at: ~U[2026-05-10 11:00:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)
      assert derived.correlated_change == %{"change_ref" => "pr-123"}
      assert derived.resolved_at == ~U[2026-05-10 11:00:00Z]
    end

    test "fallback for resolved_at is incident updated_at when state is resolved but no event" do
      incident = %Parapet.Spine.Incident{id: "inc-1", state: "resolved", updated_at: ~U[2026-05-10 09:00:00Z]}
      derived = WorkbenchContract.derive(incident, [])
      assert derived.resolved_at == ~U[2026-05-10 09:00:00Z]
    end

    test "Approval state and recommendation state are derived from explicitly keyed request/decision/recommendation events" do
      incident = %Parapet.Spine.Incident{id: "inc-1"}
      entries = [
        %Parapet.Spine.TimelineEntry{
          type: "approval_requested",
          payload: %{"approval_key" => "mitigate-1", "state" => "pending"},
          inserted_at: ~U[2026-05-10 10:00:00Z]
        },
        %Parapet.Spine.TimelineEntry{
          type: "approval_decided",
          payload: %{"approval_key" => "mitigate-1", "state" => "approved"},
          inserted_at: ~U[2026-05-10 10:05:00Z]
        },
        %Parapet.Spine.TimelineEntry{
          type: "recommendation",
          payload: %{"action" => "scale_up", "state" => "applied"},
          inserted_at: ~U[2026-05-10 10:06:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)
      assert derived.approval_state == :approved
      assert derived.recommendation_state == :applied
    end
  end

  describe "transactional seam" do
    test "run_operator_command/1 writes incident update, timeline append, and audit record together" do
      incident = %Parapet.Spine.Incident{id: "inc-1", title: "Test", state: "open"}
      incident_changeset = Ecto.Changeset.change(incident, %{state: "investigating"})
      
      timeline_attrs = %{type: "note", payload: %{"text" => "Looked into it"}, incident_id: "inc-1"}
      audit_attrs = %{tool_name: "operator_action", input: %{"action" => "mark_investigating"}, success: true}

      assert {:ok, result} = Evidence.run_operator_command(
        incident_changeset: incident_changeset,
        timeline_attrs: timeline_attrs,
        audit_attrs: audit_attrs
      )
      
      assert %Parapet.Spine.Incident{state: "investigating"} = result.incident
      assert %Parapet.Spine.TimelineEntry{type: "note"} = result.timeline_entry
      assert %Parapet.Spine.ToolAudit{tool_name: "operator_action"} = result.tool_audit
      assert result.tool_audit.timeline_entry_id == result.timeline_entry.id
    end
  end
end
