defmodule Parapet.Spine.AlertProcessorTest do
  use ExUnit.Case, async: false

  alias Parapet.Spine.AlertProcessor
  alias Parapet.Spine.{Incident, SystemEvent, TimelineEntry}

  defmodule DummyRepo do
    def all(query) do
      source = query.from |> Map.fetch!(:source) |> elem(1)

      case source do
        Parapet.Spine.SystemEvent -> Process.get(:mock_system_events, [])
        Parapet.Spine.Incident -> Process.get(:mock_incidents, [])
        Parapet.Spine.TimelineEntry -> Process.get(:mock_timeline_entries, [])
      end
    end

    def insert(changeset, _opts \\ []) do
      send(self(), {:insert, changeset})

      struct =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> maybe_assign_id()

      {:ok, struct}
    end

    def update(changeset, _opts \\ []) do
      send(self(), {:update, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def transaction(multi) do
      ops = Ecto.Multi.to_list(multi)
      send(self(), {:transaction, ops})

      Enum.reduce_while(ops, {:ok, %{}}, fn
        {name, {:insert, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
          {:ok, struct} = insert(changeset)
          {:cont, {:ok, Map.put(acc, name, struct)}}

        {name, {:insert, fun, _opts}}, {:ok, acc} ->
          {:ok, struct} = insert(fun.(acc))
          {:cont, {:ok, Map.put(acc, name, struct)}}

        {name, {:update, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
          {:ok, struct} = update(changeset)
          {:cont, {:ok, Map.put(acc, name, struct)}}

        {name, {:run, fun}}, {:ok, acc} ->
          case fun.(__MODULE__, acc) do
            {:ok, value} -> {:cont, {:ok, Map.put(acc, name, value)}}
            {:error, error} -> {:halt, {:error, name, error, acc}}
          end
      end)
    end

    defp maybe_assign_id(%Incident{} = incident) do
      Map.put(incident, :id, incident.id || Process.get(:mock_incident_id, "inc-generated"))
    end

    defp maybe_assign_id(%TimelineEntry{} = entry) do
      Map.put(entry, :id, entry.id || Ecto.UUID.generate())
    end

    defp maybe_assign_id(struct), do: struct
  end

  defmodule DummyNotifier do
    @behaviour Parapet.Notifier

    def deliver(incident, opts) do
      send(opts[:test_pid], {:broadcast, incident})
      {:ok, :delivered}
    end
  end

  setup do
    Process.put(:mock_incidents, [])
    Process.put(:mock_system_events, [])
    Process.put(:mock_timeline_entries, [])
    Process.put(:mock_incident_id, "inc-generated")

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
    test "creates a new incident for a generic firing alert" do
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

      assert_received {:transaction, ops}
      assert {:incident, {:insert, changeset, _opts}} = List.keyfind(ops, :incident, 0)

      incident = Ecto.Changeset.apply_changes(changeset)
      assert incident.title == "CPU usage is high"
      assert incident.description == "More details"
      assert incident.state == "open"
      assert incident.correlation_key == "123456"
      assert incident.runbook_data == %{}

      assert_receive {:broadcast, %Incident{correlation_key: "123456"}}
    end

    test "updates an existing correlated incident without duplicating the durable summary" do
      Process.put(:mock_incidents, [
        %Incident{
          id: "inc-existing",
          state: "open",
          correlation_key: "existing-key",
          runbook_data: %{
            "triage" => %{
              "integration" => "rindle",
              "symptom" => "queue backlog burn",
              "fault_plane" => "backlog",
              "confidence" => "medium"
            }
          }
        }
      ])

      payload = %{
        "alerts" => [
          %{
            "status" => "firing",
            "fingerprint" => "existing-key",
            "labels" => %{
              "alertname" => "RindleQueueFreshnessBurn",
              "integration" => "rindle",
              "fault_plane" => "backlog"
            },
            "annotations" => %{"summary" => "Queue backlog burn"}
          }
        ]
      }

      assert :ok = AlertProcessor.process_batch(payload)

      assert_received {:transaction, ops}
      assert {:incident, {:update, changeset, _opts}} = List.keyfind(ops, :incident, 0)
      assert {:triage_snapshot, {:run, _fun}} = List.keyfind(ops, :triage_snapshot, 0)

      incident = Ecto.Changeset.apply_changes(changeset)
      assert incident.correlation_key == "existing-key"
      assert incident.runbook_data["triage"]["fault_plane"] == "backlog"
    end

    test "correlates recent system events when a new incident is created" do
      Process.put(:mock_incident_id, "new-incident-id")

      Process.put(:mock_system_events, [
        %SystemEvent{id: "evt-1", type: "rulestead_flag_change", payload: %{"flag" => "feature_x"}}
      ])

      payload = %{
        "alerts" => [
          %{
            "status" => "firing",
            "labels" => %{"alertname" => "HighCPU"}
          }
        ]
      }

      assert :ok = AlertProcessor.process_batch(payload)

      assert_received {:insert, %Ecto.Changeset{data: %Incident{}}}
      assert_received {:insert, timeline_cs}
      assert timeline_cs.data.__struct__ == TimelineEntry
      assert Ecto.Changeset.get_field(timeline_cs, :incident_id) == "new-incident-id"
      assert Ecto.Changeset.get_field(timeline_cs, :type) == "rulestead_flag_change"
      assert Ecto.Changeset.get_field(timeline_cs, :payload) == %{"flag" => "feature_x"}
    end

    test "attaches runbook data for matching SLOs and keeps triage nested" do
      defmodule MockRunbook do
        def __runbook_schema__() do
          %{module: "MockRunbook", title: "Test", description: "Desc", steps: []}
        end
      end

      apply(Parapet.SLO, :define, [
        :RunbookAlert,
        [objective: 99.9, good_events: "up", total_events: "all", runbook: MockRunbook]
      ])

      payload = %{
        "alerts" => [
          %{
            "status" => "firing",
            "fingerprint" => "runbook-alert",
            "labels" => %{
              "alertname" => "RunbookAlert",
              "integration" => "mailglass",
              "fault_plane" => "provider"
            },
            "annotations" => %{"summary" => "Provider feedback degraded"}
          }
        ]
      }

      assert :ok = AlertProcessor.process_batch(payload)

      assert_received {:transaction, ops}
      assert {:incident, {:insert, changeset, _opts}} = List.keyfind(ops, :incident, 0)

      incident = Ecto.Changeset.apply_changes(changeset)

      assert incident.runbook_data[:module] == "MockRunbook"
      assert incident.runbook_data["triage"]["integration"] == "mailglass"
      assert incident.runbook_data["triage"]["fault_plane"] == "provider"

      Application.put_env(
        :parapet,
        :slos,
        Enum.reject(Parapet.SLO.all(), &(&1.name == :RunbookAlert))
      )
    end

    test "stores a bounded triage summary in runbook_data and keeps titles symptom-first" do
      payload = %{
        "alerts" => [
          %{
            "status" => "firing",
            "fingerprint" => "triage-1",
            "labels" => %{
              "alertname" => "RindleQueueFreshnessBurn",
              "integration" => "rindle",
              "fault_plane" => "backlog",
              "queue" => "critical_jobs",
              "delay_bucket" => "gt_10m"
            },
            "annotations" => %{
              "summary" => "Queue freshness burn",
              "impact" => "Users are waiting on async work.",
              "next_safe_action" => "Inspect queue depth before retrying."
            }
          }
        ]
      }

      assert :ok = AlertProcessor.process_batch(payload)

      assert_received {:transaction, ops}
      assert {:incident, {:insert, changeset, _opts}} = List.keyfind(ops, :incident, 0)

      incident = Ecto.Changeset.apply_changes(changeset)

      assert incident.title == "Rindle queue freshness burn"
      assert incident.runbook_data["triage"] == %{
               "integration" => "rindle",
               "symptom" => "Queue freshness burn",
               "fault_plane" => "backlog",
               "impact" => "Users are waiting on async work.",
               "queue" => "critical_jobs",
               "delay_bucket" => "gt_10m",
               "next_safe_action" => "Inspect queue depth before retrying.",
               "confidence" => "medium"
             }
    end

    test "appends a triage_snapshot when the durable classification changes" do
      Process.put(:mock_incidents, [
        %Incident{
          id: "inc-1",
          state: "open",
          correlation_key: "triage-2",
          runbook_data: %{
            "triage" => %{
              "integration" => "mailglass",
              "symptom" => "provider feedback degraded",
              "fault_plane" => "provider",
              "confidence" => "medium"
            }
          }
        }
      ])

      payload = %{
        "alerts" => [
          %{
            "status" => "firing",
            "fingerprint" => "triage-2",
            "labels" => %{
              "alertname" => "MailglassCallbackFreshnessBurn",
              "integration" => "mailglass",
              "fault_plane" => "webhook",
              "pipeline_stage" => "callback_ingest",
              "delay_bucket" => "gt_15m"
            },
            "annotations" => %{"summary" => "Callback freshness burn"}
          }
        ]
      }

      assert :ok = AlertProcessor.process_batch(payload)

      assert_received {:transaction, ops}
      assert {:triage_snapshot, _op} = List.keyfind(ops, :triage_snapshot, 0)
      assert_received {:update, %Ecto.Changeset{data: %Incident{}}}
      assert_received {:insert, snapshot_changeset}

      snapshot = Ecto.Changeset.apply_changes(snapshot_changeset)

      assert snapshot.type == "triage_snapshot"
      assert snapshot.payload["fault_plane"] == "webhook"
      assert snapshot.payload["pipeline_stage"] == "callback_ingest"
      assert [_ | _] = snapshot.payload["evidence_facts"]
    end

    test "rejects invalid payloads" do
      assert {:error, :invalid_payload} = AlertProcessor.process_batch(%{"not_alerts" => []})
      assert {:error, :invalid_payload} = AlertProcessor.process_batch("invalid")

      refute_received {:transaction, _}
    end

    test "resolved alerts close matching incidents and append auto_resolved chronology" do
      Process.put(:mock_incidents, [
        %Incident{id: "inc-1", state: "open", correlation_key: "123456"}
      ])

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
      entry = Ecto.Changeset.apply_changes(entry_cs)
      assert entry.type == "auto_resolved"
      assert entry.incident_id == "inc-1"
      assert entry.payload["status"] == "resolved"

      assert_receive {:broadcast, %Incident{state: "resolved"}}
    end

    test "ignores resolved alerts when the incident is not found" do
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
