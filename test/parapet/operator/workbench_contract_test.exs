defmodule Parapet.Operator.WorkbenchContractTest do
  use ExUnit.Case, async: false

  alias Parapet.Operator.WorkbenchContract
  alias Parapet.Spine.{Incident, TimelineEntry}

  describe "derive/2" do
    test "prefers the durable incident triage summary for current-state fields" do
      incident = %Incident{
        id: "inc-1",
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
          type: "triage_snapshot",
          payload: %{
            "integration" => "mailglass",
            "symptom" => "provider feedback degraded",
            "fault_plane" => "provider",
            "evidence_facts" => ["Provider feedback rates are falling."]
          },
          inserted_at: ~U[2026-05-10 10:00:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)

      assert derived.integration == "mailglass"
      assert derived.symptom == "callback freshness burn"
      assert derived.fault_plane == "webhook"
      assert derived.impact == "Delivery confirmations are delayed."
      assert derived.next_safe_action == "Inspect callback ingress."
      assert derived.confidence == "high"
      assert derived.evidence_facts == ["Provider feedback rates are falling."]
      assert derived.classification_updated_at == ~U[2026-05-10 10:00:00Z]
    end

    test "falls back to the latest triage_snapshot when the incident summary is absent" do
      incident = %Incident{id: "inc-1", state: "open"}

      entries = [
        %TimelineEntry{
          type: "triage_snapshot",
          payload: %{
            "integration" => "rindle",
            "symptom" => "queue backlog burn",
            "fault_plane" => "backlog",
            "impact" => "Queued work is aging.",
            "next_safe_action" => "Inspect queue depth.",
            "confidence" => "medium",
            "evidence_facts" => ["Queue critical_jobs is aging.", "Delay bucket gt_10m is present."]
          },
          inserted_at: ~U[2026-05-10 10:05:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)

      assert derived.integration == "rindle"
      assert derived.symptom == "queue backlog burn"
      assert derived.fault_plane == "backlog"
      assert derived.impact == "Queued work is aging."
      assert derived.next_safe_action == "Inspect queue depth."
      assert derived.confidence == "medium"
      assert derived.evidence_facts == ["Queue critical_jobs is aging.", "Delay bucket gt_10m is present."]
      assert derived.classification_updated_at == ~U[2026-05-10 10:05:00Z]
    end

    test "preserves chronology ordering for classification timestamps and existing approval state derivations" do
      incident = %Incident{id: "inc-1", state: "resolved", updated_at: ~U[2026-05-10 11:00:00Z]}

      entries = [
        %TimelineEntry{
          type: "approval_requested",
          payload: %{"approval_key" => "mitigate-1", "state" => "pending"},
          inserted_at: ~U[2026-05-10 09:00:00Z]
        },
        %TimelineEntry{
          type: "approval_decided",
          payload: %{"approval_key" => "mitigate-1", "state" => "approved"},
          inserted_at: ~U[2026-05-10 09:05:00Z]
        },
        %TimelineEntry{
          type: "triage_snapshot",
          payload: %{
            "integration" => "chimeway",
            "symptom" => "provider feedback missing",
            "fault_plane" => "provider",
            "evidence_facts" => ["Provider outcomes are falling behind."]
          },
          inserted_at: ~U[2026-05-10 10:00:00Z]
        },
        %TimelineEntry{
          type: "incident_resolved",
          payload: %{},
          inserted_at: ~U[2026-05-10 10:30:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)

      assert derived.approval_state == :approved
      assert derived.recommendation_state == :none
      assert derived.resolved_at == ~U[2026-05-10 10:30:00Z]
      assert derived.classification_updated_at == ~U[2026-05-10 10:00:00Z]
    end

    test "does not parse titles or descriptions when no durable triage evidence exists" do
      incident = %Incident{
        id: "inc-1",
        state: "open",
        title: "Mailglass provider is down",
        description: "Human wording that should not drive triage"
      }

      derived = WorkbenchContract.derive(incident, [])

      assert derived.symptom == nil
      assert derived.fault_plane == nil
      assert derived.evidence_facts == []
      assert derived.classification_updated_at == nil
    end
  end
end
