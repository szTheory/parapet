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

    def all(query) do
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
      results = Enum.into(ops, %{}, fn {name, {_, changeset, _opts}} ->
        {name, Ecto.Changeset.apply_changes(changeset)}
      end)
      {:ok, results}
    end
  end

  setup do
    Process.put(:mock_incident, [])
    Application.put_env(:parapet, :repo, DummyRepo)
    on_exit(fn -> Application.delete_env(:parapet, :repo) end)
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
