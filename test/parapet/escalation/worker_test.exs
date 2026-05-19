defmodule Parapet.Escalation.WorkerTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset, _opts \\ []) do
      send(self(), {:insert, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def get(Parapet.Spine.Incident, "not-found"), do: nil
    def get(Parapet.Spine.Incident, "open-id"), do: %Parapet.Spine.Incident{id: "open-id", state: "open"}
    def get(Parapet.Spine.Incident, "suppressed-id"),
      do: %Parapet.Spine.Incident{
        id: "suppressed-id",
        state: "open",
        runbook_data: %{
          "escalation" => %{
            "suppressed_until" => DateTime.utc_now() |> DateTime.add(600, :second) |> DateTime.truncate(:second),
            "suppressed_by" => "operator-1",
            "suppression_reason" => "stabilizing downstream"
          }
        }
      }

    def get(Parapet.Spine.Incident, "manual-trigger-id"),
      do: %Parapet.Spine.Incident{
        id: "manual-trigger-id",
        state: "open",
        runbook_data: %{
          "escalation" => %{
            "pending_trigger" => true,
            "triggered_by" => "operator-2",
            "trigger_reason" => "page the next responder"
          }
        }
      }

    def get(Parapet.Spine.Incident, "inv-id"), do: %Parapet.Spine.Incident{id: "inv-id", state: "investigating"}
    def get(Parapet.Spine.Incident, "res-id"), do: %Parapet.Spine.Incident{id: "res-id", state: "resolved"}
  end

  defmodule SuccessPolicy do
    @behaviour Parapet.Escalation.Policy
    def escalate(_incident, _opts), do: {:ok, "success"}
  end

  defmodule ErrorPolicy do
    @behaviour Parapet.Escalation.Policy
    def escalate(_incident, _opts), do: {:error, "failed"}
  end

  defmodule ExceptionPolicy do
    @behaviour Parapet.Escalation.Policy
    def escalate(_incident, _opts), do: raise("boom")
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    
    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
      Application.delete_env(:parapet, :escalation_policy)
    end)
    :ok
  end

  test "returns {:discard, reason} if incident not found" do
    assert {:discard, "Incident not-found not found"} = 
             Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "not-found"}})
  end

  test "returns {:discard, reason} and appends timeline if state is investigating" do
    assert {:discard, "Short-circuited (already investigating)"} = 
             Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "inv-id"}})
             
    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "inv-id"
    assert entry.type == "escalation_short_circuited"
    assert entry.payload["reason"] == "already_investigating"
  end

  test "returns {:discard, reason} and appends timeline if state is resolved" do
    assert {:discard, "Short-circuited (already resolved)"} = 
             Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "res-id"}})
             
    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "res-id"
    assert entry.type == "escalation_short_circuited"
    assert entry.payload["reason"] == "already_resolved"
  end

  test "short-circuits when a suppression window is active" do
    assert {:discard, "Short-circuited (suppressed)"} =
             Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "suppressed-id"}})

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "suppressed-id"
    assert entry.type == "escalation_short_circuited"
    assert entry.payload["reason"] == "suppressed"
    assert entry.payload["suppressed_by"] == "operator-1"
    assert entry.payload["suppression_reason"] == "stabilizing downstream"
    assert %DateTime{} = entry.payload["suppressed_until"]
  end
  
  test "executes policy when state is open and returns :ok on success" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})
    
    assert :ok = Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "open-id"}})
    
    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "open-id"
    assert entry.type == "escalation_executed"
    assert entry.payload["status"] == "success"
    assert entry.payload["details"] == inspect("success")
    assert entry.payload["mode"] == "scheduled"
  end

  test "manual trigger execution records manual chronology without bypassing the worker" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})

    assert :ok =
             Parapet.Escalation.Worker.perform(
               %Oban.Job{args: %{"incident_id" => "manual-trigger-id"}}
             )

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "manual-trigger-id"
    assert entry.type == "escalation_executed"
    assert entry.payload["status"] == "success"
    assert entry.payload["mode"] == "manual"
    assert entry.payload["triggered_by"] == "operator-2"
    assert entry.payload["trigger_reason"] == "page the next responder"
  end

  test "executes policy when state is open and returns {:error, reason} on error" do
    Application.put_env(:parapet, :escalation_policy, {ErrorPolicy, []})
    
    assert {:error, _} = Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "open-id"}})
    
    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "open-id"
    assert entry.type == "escalation_executed"
    assert entry.payload["status"] == "error"
    assert entry.payload["details"] == inspect("failed")
    assert entry.payload["mode"] == "scheduled"
  end
  
  test "executes policy when state is open and returns {:error, reason} on exception" do
    Application.put_env(:parapet, :escalation_policy, {ExceptionPolicy, []})
    
    assert {:error, _} = Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "open-id"}})
    
    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "open-id"
    assert entry.type == "escalation_executed"
    assert entry.payload["status"] == "error"
    assert entry.payload["details"] =~ "boom"
    assert entry.payload["mode"] == "scheduled"
  end
end
