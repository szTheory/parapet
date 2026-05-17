defmodule Parapet.OperatorTest do
  use ExUnit.Case, async: false

  alias Parapet.Operator
  alias Parapet.Operator.ActionPayload
  alias Parapet.Spine.{Incident, TimelineEntry, ToolAudit}

  defmodule DummyRepo do
    def all(query) do
      send(self(), {:repo_all, query})

      source = query.from |> Map.fetch!(:source) |> elem(1)

      case source do
        Parapet.Spine.TimelineEntry -> Process.get(:mock_entries, [])
        Parapet.Spine.ActionItem -> Process.get(:mock_action_items, [])
        _ -> []
      end
    end

    def one(_query), do: nil

    def get!(Parapet.Spine.Incident, id) do
      Process.get(:mock_incident) ||
        %Incident{id: id, state: "open", updated_at: ~U[2026-05-10 10:00:00Z]}
    end

    def insert(changeset, _opts \\ []) do
      {:ok, Ecto.Changeset.apply_changes(changeset) |> Map.put(:id, Ecto.UUID.generate())}
    end

    def update(changeset, _opts \\ []) do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def transaction(multi) do
      multi
      |> Ecto.Multi.to_list()
      |> Enum.reduce_while({:ok, %{}}, fn
        {name, {:update, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
          {:cont, {:ok, Map.put(acc, name, Ecto.Changeset.apply_changes(changeset))}}

        {name, {:insert, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
          {:cont, {:ok, Map.put(acc, name, Ecto.Changeset.apply_changes(changeset) |> Map.put(:id, Ecto.UUID.generate()))}}

        {name, {:insert, fun, _opts}}, {:ok, acc} ->
          struct = fun.(acc) |> Ecto.Changeset.apply_changes() |> Map.put(:id, Ecto.UUID.generate())
          {:cont, {:ok, Map.put(acc, name, struct)}}

        {name, {:run, fun}}, {:ok, acc} ->
          case fun.(__MODULE__, acc) do
            {:ok, value} -> {:cont, {:ok, Map.put(acc, name, value)}}
            {:error, error} -> {:halt, {:error, name, error, acc}}
          end
      end)
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    Process.put(:mock_entries, [])
    Process.put(:mock_action_items, [])
    Process.put(:mock_incident, nil)

    on_exit(fn -> Application.delete_env(:parapet, :repo) end)
    :ok
  end

  describe "queue listing" do
    test "queue_query keeps open and investigating incidents ahead of resolved incidents" do
      query = Operator.queue_query()
      query_str = inspect(query)

      assert %Ecto.Query{} = query
      assert query_str =~ "order_by:"
      assert query_str =~ "updated_at"
    end

    test "action_items_query returns only open action items in insertion order" do
      query = Operator.action_items_query()
      query_str = inspect(query)

      assert %Ecto.Query{} = query
      assert query_str =~ "state == \"open\""
      assert query_str =~ "inserted_at"
    end
  end

  describe "incident_detail/1" do
    test "returns an evidence-first payload with chronology ordered ascending" do
      incident = %Incident{
        id: "inc-123",
        state: "open",
        runbook_data: %{
          "triage" => %{
            "integration" => "mailglass",
            "symptom" => "callback freshness burn",
            "fault_plane" => "webhook",
            "impact" => "Delivery confirmations are delayed.",
            "next_safe_action" => "Inspect callback ingress.",
            "confidence" => "high"
          }
        }
      }

      entries = [
        %TimelineEntry{
          incident_id: "inc-123",
          type: "triage_snapshot",
          payload: %{
            "integration" => "mailglass",
            "symptom" => "callback freshness burn",
            "fault_plane" => "webhook",
            "evidence_facts" => ["Delay bucket gt_15m is present."]
          },
          inserted_at: ~U[2026-05-10 10:00:00Z]
        },
        %TimelineEntry{
          incident_id: "inc-123",
          type: "external_link",
          payload: %{"label" => "Grafana", "url" => "https://grafana.example.com"},
          inserted_at: ~U[2026-05-10 10:01:00Z]
        }
      ]

      Process.put(:mock_incident, incident)
      Process.put(:mock_entries, entries)

      detail = Operator.incident_detail("inc-123")

      assert_received {:repo_all, query}
      assert inspect(query) =~ "order_by: [asc: t0.inserted_at]"

      assert detail.incident == incident
      assert detail.entries == entries
      assert detail.external_links == [%{"label" => "Grafana", "url" => "https://grafana.example.com"}]
      assert detail.derived.symptom == "callback freshness burn"
      assert detail.derived.fault_plane == "webhook"
      assert detail.derived.evidence_facts == ["Delay bucket gt_15m is present."]
    end
  end

  describe "first-class commands" do
    setup do
      valid_payload = %{
        actor: "user_1",
        reason: "testing",
        correlation_id: "req_1",
        action_type: :immutable_fact
      }

      {:ok, payload} =
        ActionPayload.changeset(%ActionPayload{}, valid_payload)
        |> Ecto.Changeset.apply_action(:insert)

      %{payload: payload, incident: %Incident{id: Ecto.UUID.generate(), state: "open"}}
    end

    test "mark_investigating preserves the audited operator command seam", %{payload: payload, incident: incident} do
      assert {:ok, result} = Operator.mark_investigating(incident, payload)
      assert %Incident{state: "investigating"} = result.incident
      assert %TimelineEntry{type: "status_change", payload: %{"new_state" => "investigating"}} = result.timeline_entry
      assert %ToolAudit{tool_name: "operator_mark_investigating"} = result.tool_audit
    end

    test "commands require a valid ActionPayload struct" do
      incident = %Incident{id: Ecto.UUID.generate(), state: "open"}
      invalid_payload = %ActionPayload{actor: nil}

      assert {:error, :invalid_payload} = Operator.mark_investigating(incident, invalid_payload)
    end
  end
end
