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
        Parapet.Spine.Incident -> Process.get(:mock_incidents, [])
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
          {:cont,
           {:ok,
            Map.put(
              acc,
              name,
              Ecto.Changeset.apply_changes(changeset) |> Map.put(:id, Ecto.UUID.generate())
            )}}

        {name, {:insert, fun, _opts}}, {:ok, acc} ->
          struct =
            fun.(acc) |> Ecto.Changeset.apply_changes() |> Map.put(:id, Ecto.UUID.generate())

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
    Process.put(:mock_incidents, [])
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

    test "list_incident_queue/1 loads a bounded active-only page" do
      now = ~U[2026-05-10 10:00:00Z]

      Process.put(:mock_incidents, [
        %Incident{
          id: "inc-3",
          state: "open",
          updated_at: now,
          title: "Newest",
          runbook_data: %{
            "triage" => %{"integration" => "mailglass", "symptom" => "Delivery burn"},
            "approval" => %{"state" => "pending"}
          }
        },
        %Incident{id: "inc-2", state: "investigating", updated_at: now, title: "Current"},
        %Incident{id: "inc-1", state: "open", updated_at: ~U[2026-05-10 09:59:00Z], title: "Older"}
      ])

      page = Operator.list_incident_queue(page_size: 2)

      assert_received {:repo_all, query}

      query_str = inspect(query)

      assert query_str =~ "state in ^[\"open\", \"investigating\"]"
      assert query_str =~ "updated_at"
      assert query_str =~ "id"
      assert page.scope == :active
      assert page.page_size == 2
      assert page.direction == :next
      assert Enum.map(page.items, & &1.incident_id) == ["inc-3", "inc-2"]
      assert page.has_next_page? == true
      assert page.has_previous_page? == false
      assert is_binary(page.next_cursor)
      assert is_nil(page.previous_cursor)

      assert [
               %{
                 incident_id: "inc-3",
                 state: "open",
                 title: "Delivery burn",
                 secondary_line: "mailglass",
                 attention_chip: "Approval pending"
               },
               %{
                 incident_id: "inc-2",
                 state: "investigating"
               }
             ] = page.items
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

      assert detail.external_links == [
               %{"label" => "Grafana", "url" => "https://grafana.example.com"}
             ]

      assert detail.derived.symptom == "callback freshness burn"
      assert detail.derived.fault_plane == "webhook"
      assert detail.derived.evidence_facts == ["Delay bucket gt_15m is present."]
    end

    test "returns escalation-aware derived detail and timeline helpers without hiding canonical evidence" do
      suppressed_until =
        DateTime.utc_now() |> DateTime.add(900, :second) |> DateTime.truncate(:second)

      next_escalation_at =
        DateTime.utc_now() |> DateTime.add(1_800, :second) |> DateTime.truncate(:second)

      incident = %Incident{
        id: "inc-123",
        state: "open",
        runbook_data: %{
          "title" => "Mailglass Recovery",
          "triage" => %{
            "integration" => "mailglass",
            "symptom" => "callback freshness burn",
            "fault_plane" => "webhook",
            "impact" => "Delivery confirmations are delayed.",
            "next_safe_action" => "Inspect callback ingress.",
            "confidence" => "high"
          },
          "escalation" => %{
            "suppressed_until" => suppressed_until,
            "suppressed_by" => "operator_ui",
            "suppression_reason" => "Waiting for provider callback",
            "next_escalation_at" => next_escalation_at,
            "current_step_id" => "sms",
            "chain" => [
              %{
                "id" => "slack",
                "label" => "Slack page",
                "delay" => "0m",
                "status" => "completed"
              },
              %{"id" => "sms", "label" => "SMS escalation", "delay" => "15m"},
              %{"id" => "phone_tree", "label" => "Phone tree", "delay" => "30m"}
            ]
          }
        }
      }

      entries = [
        %TimelineEntry{
          incident_id: "inc-123",
          type: "external_link",
          payload: %{"label" => "Grafana", "url" => "https://grafana.example.com"},
          inserted_at: DateTime.add(suppressed_until, -180, :second)
        },
        %TimelineEntry{
          incident_id: "inc-123",
          type: "escalation_suppressed",
          payload: %{
            "actor" => "operator_ui",
            "reason" => "Waiting for provider callback",
            "suppressed_until" => suppressed_until
          },
          inserted_at: DateTime.add(suppressed_until, -120, :second)
        },
        %TimelineEntry{
          incident_id: "inc-123",
          type: "mitigation_executed",
          payload: %{"actor" => "system:automation:executor", "step_id" => "retry_delivery"},
          inserted_at: DateTime.add(suppressed_until, -60, :second)
        }
      ]

      Process.put(:mock_incident, incident)
      Process.put(:mock_entries, entries)

      detail = Operator.incident_detail("inc-123")

      assert detail.entries == entries

      assert detail.external_links == [
               %{"label" => "Grafana", "url" => "https://grafana.example.com"}
             ]

      assert detail.derived.runbook_title == "Mailglass Recovery"
      assert detail.derived.escalation_summary.status == :suppressed
      assert detail.derived.escalation_summary.suppression.until == suppressed_until
      assert detail.derived.escalation_summary.time_until_next_escalation.at == suppressed_until

      assert [%{status: :completed}, %{status: :current}, %{status: :pending}] =
               detail.derived.escalation_summary.escalation_chain

      assert detail.escalation_summary == detail.derived.escalation_summary

      assert [
               %{
                 entry: %TimelineEntry{type: "external_link"},
                 presentation: %{actor_class: :external, system_action?: false}
               },
               %{
                 entry: %TimelineEntry{type: "escalation_suppressed"},
                 presentation: %{actor_class: :operator, style_variant: :operator_action}
               },
               %{
                 entry: %TimelineEntry{type: "mitigation_executed"},
                 presentation: %{
                   actor_class: :system,
                   style_variant: :system_action,
                   system_action?: true
                 }
               }
             ] = detail.timeline_entries
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

    test "mark_investigating preserves the audited operator command seam", %{
      payload: payload,
      incident: incident
    } do
      assert {:ok, result} = Operator.mark_investigating(incident, payload)
      assert %Incident{state: "investigating"} = result.incident

      assert %TimelineEntry{type: "status_change", payload: %{"new_state" => "investigating"}} =
               result.timeline_entry

      assert %ToolAudit{tool_name: "operator_mark_investigating"} = result.tool_audit
    end

    test "commands require a valid ActionPayload struct" do
      incident = %Incident{id: Ecto.UUID.generate(), state: "open"}
      invalid_payload = %ActionPayload{actor: nil}

      assert {:error, :invalid_payload} = Operator.mark_investigating(incident, invalid_payload)
    end

    test "trigger_next_escalation writes typed manual escalation evidence", %{
      payload: payload,
      incident: incident
    } do
      assert {:ok, result} = Operator.trigger_next_escalation(incident, payload)

      assert %Incident{runbook_data: runbook_data} = result.incident
      assert get_in(runbook_data, ["escalation", "pending_trigger"]) == true
      assert get_in(runbook_data, ["escalation", "triggered_by"]) == payload.actor
      assert get_in(runbook_data, ["escalation", "trigger_reason"]) == payload.reason

      assert %TimelineEntry{
               type: "escalation_trigger_requested",
               payload: %{
                 "actor" => actor,
                 "reason" => reason,
                 "mode" => "manual",
                 "pending_trigger" => true
               }
             } = result.timeline_entry

      assert actor == payload.actor
      assert reason == payload.reason
      assert %ToolAudit{tool_name: "operator_trigger_next_escalation"} = result.tool_audit
    end

    test "suppress_pending_escalation stores a bounded suppression window", %{
      payload: payload,
      incident: incident
    } do
      expires_at = DateTime.utc_now() |> DateTime.add(900, :second) |> DateTime.truncate(:second)

      assert {:ok, result} =
               Operator.suppress_pending_escalation(incident, expires_at, payload)

      assert %Incident{state: "open", runbook_data: runbook_data} = result.incident
      assert get_in(runbook_data, ["escalation", "suppressed_until"]) == expires_at
      assert get_in(runbook_data, ["escalation", "suppressed_by"]) == payload.actor
      assert get_in(runbook_data, ["escalation", "suppression_reason"]) == payload.reason

      assert %TimelineEntry{
               type: "escalation_suppressed",
               payload: %{
                 "actor" => actor,
                 "reason" => reason,
                 "suppressed_until" => ^expires_at
               }
             } = result.timeline_entry

      assert actor == payload.actor
      assert reason == payload.reason
      assert %ToolAudit{tool_name: "operator_suppress_pending_escalation"} = result.tool_audit
    end

    test "manual escalation commands reject invalid incident states", %{payload: payload} do
      investigating = %Incident{id: Ecto.UUID.generate(), state: "investigating"}
      resolved = %Incident{id: Ecto.UUID.generate(), state: "resolved"}
      expires_at = DateTime.utc_now() |> DateTime.add(900, :second) |> DateTime.truncate(:second)

      assert {:error, :invalid_incident_state} =
               Operator.trigger_next_escalation(investigating, payload)

      assert {:error, :invalid_incident_state} =
               Operator.suppress_pending_escalation(investigating, expires_at, payload)

      assert {:error, :invalid_incident_state} =
               Operator.trigger_next_escalation(resolved, payload)

      assert {:error, :invalid_incident_state} =
               Operator.suppress_pending_escalation(resolved, expires_at, payload)
    end

    test "manual escalation commands reject invalid payloads and windows", %{payload: payload} do
      incident = %Incident{id: Ecto.UUID.generate(), state: "open"}
      invalid_payload = %ActionPayload{actor: nil}
      past_expiry = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.truncate(:second)

      too_far_expiry =
        DateTime.utc_now() |> DateTime.add(86_401, :second) |> DateTime.truncate(:second)

      assert {:error, :invalid_payload} =
               Operator.trigger_next_escalation(incident, invalid_payload)

      assert {:error, :invalid_suppression_window} =
               Operator.suppress_pending_escalation(incident, past_expiry, payload)

      assert {:error, :invalid_suppression_window} =
               Operator.suppress_pending_escalation(incident, too_far_expiry, payload)
    end
  end

  describe "recovery execution" do
    defmodule MockRunbook do
      use Parapet.Runbook
      title("Mock Runbook")
      step(:retry, capability: :retry_async_item, target_kind: "async_item")
    end

    setup do
      # Ensure registry is fresh (manual reset for tests)
      Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)

      Parapet.Capabilities.register_recovery(:retry_async_item,
        name: "Retry Item",
        target_kind: "async_item",
        execute: fn _incident, _refs -> {:ok, :executed} end
      )

      valid_payload = %{
        actor: "user_1",
        reason: "testing",
        correlation_id: "req_1",
        action_type: :execute_mitigation,
        idempotency_key: "idem_1"
      }

      {:ok, payload} =
        ActionPayload.changeset(%ActionPayload{}, valid_payload)
        |> Ecto.Changeset.apply_action(:insert)

      incident = %Incident{
        id: Ecto.UUID.generate(),
        state: "open",
        runbook_data: %{"module" => to_string(MockRunbook)}
      }

      %{payload: payload, incident: incident}
    end

    test "preview_runbook_step generates a bounded preview and records evidence", %{
      payload: payload,
      incident: incident
    } do
      assert {:ok, result} = Operator.preview_runbook_step(incident, :retry, payload)
      assert %{preview: preview} = result
      assert preview["capability"] == "retry_async_item"
      assert preview["preview_token"] != nil
      assert %TimelineEntry{type: "recovery_preview"} = result.timeline_entry
    end

    test "confirm_runbook_step executes and rejects stale previews", %{
      payload: payload,
      incident: incident
    } do
      # 1. Preview first
      {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
      token = preview["preview_token"]

      # Mock the entry in the Repo so confirm can find it
      entry = %TimelineEntry{
        incident_id: incident.id,
        type: "recovery_preview",
        payload: preview,
        inserted_at: DateTime.utc_now()
      }

      Process.put(:mock_entries, [entry])

      # 2. Confirm
      assert {:ok, result} = Operator.confirm_runbook_step(incident, :retry, token, payload)
      assert %TimelineEntry{type: "recovery_confirmed"} = result.timeline_entry

      # 3. Test stale preview (expired)
      expired_preview =
        Map.put(preview, "expires_at", DateTime.utc_now() |> DateTime.add(-10, :second))

      expired_entry = %TimelineEntry{entry | payload: expired_preview}
      Process.put(:mock_entries, [expired_entry])

      assert {:error, :stale_preview} =
               Operator.confirm_runbook_step(incident, :retry, token, payload)
    end

    test "missing or unwired capability returns error", %{payload: payload, incident: incident} do
      defmodule UnwiredRunbook do
        use Parapet.Runbook
        step(:ghost, capability: :request_manual_provider_check)
      end

      unwired_incident =
        %{incident | runbook_data: %{"module" => to_string(UnwiredRunbook)}}

      # Capability not registered
      assert {:error, :capability_unwired} =
               Operator.preview_runbook_step(unwired_incident, :ghost, payload)
    end
  end
end
