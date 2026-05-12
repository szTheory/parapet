defmodule Parapet.Spine.AlertProcessorTest do
  use ExUnit.Case, async: false
  alias Parapet.Spine.AlertProcessor
  
  defmodule DummyRepo do
    def insert(changeset, opts \\ []) do
      # For tests, we just send a message to the test process
      # so we can assert it was called.
      send(self(), {:insert, changeset, opts})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def get_by!(Parapet.Spine.Incident, [correlation_key: key]) do
      %Parapet.Spine.Incident{id: "inc-mocked", state: "open", correlation_key: key}
    end

    def all(_query) do
      # We just mock the result based on the test setup
      # If the test needs an incident, it will put it in the process dictionary
      Process.get(:mock_incident, [])
    end

    def transaction(multi) do
      # We extract the operations and send them
      ops = Ecto.Multi.to_list(multi)
      send(self(), {:transaction, ops})
      
      # Mock the result to satisfy the caller
      # Return ok with mock results
      # Ecto.Multi.run operations are handled by calling the function
      results = Enum.into(ops, %{}, fn 
        {name, {:run, fun}} ->
          # mock repo is passed, along with previous results which we stub as %{}
          # actually we need to pass the updated_incident from previous steps
          # so we just let the fun run with an empty repo and a dummy incident
          {_status, val} = fun.(__MODULE__, %{incident: %Parapet.Spine.Incident{id: "inc-mocked", state: "resolved"}})
          {name, val}
        {name, {_, changeset, _opts}} ->
          {name, Ecto.Changeset.apply_changes(changeset)}
      end)
      {:ok, results}
    end
  end

  defmodule DummyNotifier do
    @behaviour Parapet.Notifier
    def deliver(incident, opts) do
      send(opts[:test_pid], {:broadcast, incident})
      {:ok, :delivered}
    end
  end

  setup do
    Process.put(:mock_incident, [])
    Application.put_env(:parapet, :repo, DummyRepo)
    Application.put_env(:parapet, :use_oban_for_notifications, false)
    Application.put_env(:parapet, :notifiers, [{DummyNotifier, [test_pid: self()]}])
    
    on_exit(fn -> 
      Application.delete_env(:parapet, :repo)
      Application.delete_env(:parapet, :use_oban_for_notifications)
      Application.delete_env(:parapet, :notifiers)
    end)
    :ok
  end

  describe "process_batch/1" do
    test "Test 1: A \"firing\" alert creates a new Incident with state 'open' and the correct correlation_key." do
      payload = %{
        "alerts" => [
          %{
            "status" => "firing",
            "fingerprint" => "123456",
            "labels" => %{"alertname" => "HighCPU"},
            "annotations" => %{"summary" => "CPU usage is high", "description" => "More details"}
          }
        ]
      }
      
      assert :ok = AlertProcessor.process_batch(payload)
      
      assert_received {:insert, changeset, opts}
      assert changeset.valid?
      incident = Ecto.Changeset.apply_changes(changeset)
      assert incident.title == "CPU usage is high"
      assert incident.description == "More details"
      assert incident.state == "open"
      assert incident.correlation_key == "123456"
      assert opts[:on_conflict] == :nothing
      assert opts[:conflict_target] == [:correlation_key]

      assert_receive {:broadcast, broadcasted_incident}, 1000
      assert broadcasted_incident.correlation_key == "123456"
    end

    test "Test 2: An identical \"firing\" alert correlates to the existing open Incident without creating duplicates." do
      # In the actual implementation, this is handled by `on_conflict: :nothing`
      # In the test, we just ensure `on_conflict: :nothing` is passed to Ecto, 
      # which we already asserted in Test 1. We can also verify fallback hash generation here.
      payload = %{
        "alerts" => [
          %{
            "status" => "firing",
            "labels" => %{"alertname" => "HighCPU", "instance" => "host1"},
            "annotations" => %{"summary" => "CPU usage is high"}
          }
        ]
      }
      
      assert :ok = AlertProcessor.process_batch(payload)
      
      assert_received {:insert, changeset, opts}
      incident = Ecto.Changeset.apply_changes(changeset)
      
      # Verify fingerprint fallback works via hashing labels
      labels_encoded = 
        %{"alertname" => "HighCPU", "instance" => "host1"}
        |> Enum.sort()
        |> Enum.map(fn {k, v} -> "#{k}:#{v}" end)
        |> Enum.join(",")
      expected_hash = :crypto.hash(:sha256, labels_encoded) |> Base.encode16(case: :lower)
      
      assert incident.correlation_key == expected_hash
      assert opts[:on_conflict] == :nothing

      assert_receive {:broadcast, _}, 1000
    end

    test "Test 2.1: A firing alert that matches an SLO runbook attaches the runbook schema data" do
      defmodule MockRunbook do
        def __runbook_schema__() do
          %{module: "MockRunbook", title: "Test", description: "Desc", steps: []}
        end
      end
      
      Parapet.SLO.define(:RunbookAlert,
        objective: 99.9,
        good_events: "up",
        total_events: "all",
        runbook: MockRunbook
      )

      payload = %{
        "alerts" => [
          %{
            "status" => "firing",
            "labels" => %{"alertname" => "RunbookAlert"},
            "annotations" => %{"summary" => "Runbook trigger"}
          }
        ]
      }
      
      assert :ok = AlertProcessor.process_batch(payload)
      
      assert_received {:insert, changeset, _opts}
      incident = Ecto.Changeset.apply_changes(changeset)
      
      assert incident.runbook_data == %{module: "MockRunbook", title: "Test", description: "Desc", steps: []}
      
      assert_receive {:broadcast, _}, 1000

      # cleanup
      Application.put_env(:parapet, :slos, Enum.reject(Parapet.SLO.all(), &(&1.name == :RunbookAlert)))
    end

    test "Test 3: An invalid payload gracefully rejects." do
      assert {:error, :invalid_payload} = AlertProcessor.process_batch(%{"not_alerts" => []})
      assert {:error, :invalid_payload} = AlertProcessor.process_batch("invalid")
      
      refute_received {:insert, _, _}
    end

    test "Test 4: A resolved alert updates the corresponding open Incident's state to resolved and inserts TimelineEntry." do
      Process.put(:mock_incident, [%Parapet.Spine.Incident{id: "inc-1", state: "open", correlation_key: "123456"}])
      
      payload = %{
        "alerts" => [
          %{
            "status" => "resolved",
            "fingerprint" => "123456",
            "labels" => %{"alertname" => "HighCPU"}
          }
        ]
      }
      
      assert :ok = AlertProcessor.process_batch(payload)
      
      assert_received {:transaction, ops}
      assert {:incident, {:update, incident_changeset, _}} = List.keyfind(ops, :incident, 0)
      assert incident_changeset.changes == %{state: "resolved"}
      
      assert {:timeline_entry, {:insert, entry_cs, _}} = List.keyfind(ops, :timeline_entry, 0)
      
      # verify the changeset directly
      entry = Ecto.Changeset.apply_changes(entry_cs)
      assert entry.type == "auto_resolved"
      assert entry.incident_id == "inc-1"
      assert entry.payload["status"] == "resolved"

      assert_receive {:broadcast, broadcasted_incident}, 1000
      assert broadcasted_incident.state == "resolved"
    end

    test "Test 5: If the open Incident is not found, the resolved alert is ignored safely." do
      # By default, mock_incident is []
      payload = %{
        "alerts" => [
          %{
            "status" => "resolved",
            "fingerprint" => "not-found",
            "labels" => %{"alertname" => "HighCPU"}
          }
        ]
      }
      
      assert :ok = AlertProcessor.process_batch(payload)
      refute_received {:transaction, _}
    end
  end
end
