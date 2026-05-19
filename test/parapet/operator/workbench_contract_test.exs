defmodule Parapet.Operator.WorkbenchContractTest do
  use ExUnit.Case, async: false

  alias Parapet.Operator.WorkbenchContract
  alias Parapet.Spine.{Incident, TimelineEntry}

  describe "derive/2" do
    test "derives escalation status, suppression metadata, and next-step facts from durable evidence" do
      suppressed_until = DateTime.utc_now() |> DateTime.add(1_200, :second) |> DateTime.truncate(:second)

      incident = %Incident{
        id: "inc-1",
        state: "open",
        runbook_data: %{
          "escalation" => %{
            "suppressed_until" => suppressed_until,
            "suppressed_by" => "operator_ui",
            "suppression_reason" => "Waiting for provider callback",
            "trigger_requested_at" => ~U[2026-05-10 10:05:00Z]
          }
        }
      }

      entries = [
        %TimelineEntry{
          type: "escalation_trigger_requested",
          payload: %{
            "actor" => "operator_ui",
            "reason" => "Escalate if callback does not recover",
            "mode" => "manual",
            "pending_trigger" => true
          },
          inserted_at: DateTime.add(suppressed_until, -120, :second)
        },
        %TimelineEntry{
          type: "escalation_suppressed",
          payload: %{
            "actor" => "operator_ui",
            "reason" => "Waiting for provider callback",
            "suppressed_until" => suppressed_until
          },
          inserted_at: DateTime.add(suppressed_until, -60, :second)
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)

      assert derived.escalation_summary.status == :suppressed
      assert derived.escalation_summary.suppression.active? == true
      assert derived.escalation_summary.suppression.until == suppressed_until
      assert derived.escalation_summary.suppression.actor == "operator_ui"
      assert derived.escalation_summary.suppression.reason == "Waiting for provider callback"
      assert derived.escalation_summary.pending_trigger? == false
      assert derived.escalation_summary.next_step.kind == :await_suppression_expiry
      assert derived.escalation_summary.next_step.at == suppressed_until
      assert derived.escalation_summary.next_step.derived? == true
      assert derived.escalation_summary.latest_event.type == "escalation_suppressed"
      assert derived.escalation_summary.latest_event.at == DateTime.add(suppressed_until, -60, :second)
    end

    test "classifies system, operator, and copilot actions explicitly for timeline presentation" do
      incident = %Incident{id: "inc-1", state: "open"}

      entries = [
        %TimelineEntry{
          type: "mitigation_executed",
          payload: %{"actor" => "system:automation:executor", "step_id" => "retry_delivery"},
          inserted_at: ~U[2026-05-10 10:00:00Z]
        },
        %TimelineEntry{
          type: "escalation_trigger_requested",
          payload: %{"actor" => "operator_ui", "reason" => "Escalate now"},
          inserted_at: ~U[2026-05-10 10:01:00Z]
        },
        %TimelineEntry{
          type: "recommendation",
          payload: %{"actor" => "ai:copilot", "state" => "pending"},
          inserted_at: ~U[2026-05-10 10:02:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)

      assert [
               %{actor_class: :system, style_variant: :system_action, system_action?: true},
               %{actor_class: :operator, style_variant: :operator_action, system_action?: false},
               %{actor_class: :copilot, style_variant: :copilot_action, system_action?: false}
             ] = derived.timeline_presentations
    end

    test "keeps chronology timestamps authoritative when summarizing recent system activity" do
      trigger_requested_at = ~U[2026-05-10 10:00:00Z]

      incident = %Incident{
        id: "inc-1",
        state: "open",
        runbook_data: %{
          "escalation" => %{
            "pending_trigger" => true,
            "triggered_by" => "operator_ui",
            "trigger_reason" => "Escalate if automation stalls",
            "trigger_requested_at" => trigger_requested_at
          }
        }
      }

      entries = [
        %TimelineEntry{
          type: "escalation_trigger_requested",
          payload: %{"actor" => "operator_ui", "reason" => "Escalate if automation stalls"},
          inserted_at: trigger_requested_at
        },
        %TimelineEntry{
          type: "escalation_executed",
          payload: %{"mode" => "manual", "status" => "success", "policy" => "PagerPolicy"},
          inserted_at: ~U[2026-05-10 10:03:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)

      assert derived.escalation_summary.status == :recently_executed
      assert derived.escalation_summary.pending_trigger? == false
      assert derived.escalation_summary.latest_event.type == "escalation_executed"
      assert derived.escalation_summary.latest_event.at == ~U[2026-05-10 10:03:00Z]
      assert derived.escalation_summary.system_action.status == :executed
      assert derived.escalation_summary.system_action.at == ~U[2026-05-10 10:03:00Z]
      assert derived.escalation_summary.system_action.mode == "manual"
      assert derived.escalation_summary.system_action.derived? == true
    end

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

    test "derives runbook steps with previewable and guidance distinctions" do
      incident = %Incident{
        id: "inc-1",
        runbook_data: %{
          "title" => "Mailglass Recovery",
          "description" => "Recovery steps for Mailglass",
          "steps" => [
            %{id: "step-1", label: "Check status", preview_only: true},
            %{id: "step-2", label: "Retry delivery", requires_preview: true, target_kind: "suppressed_delivery"},
            %{id: "step-3", label: "Direct mitigation", requires_preview: false}
          ]
        }
      }

      action_items = [
        %{id: "ai-1", kind: "suppressed_delivery", title: "Suppressed delivery for item X", external_id: "ext-1"}
      ]

      entries = [
        %TimelineEntry{
          type: "recovery_preview",
          payload: %{
            "step_id" => "step-2",
            "preview_token" => "token-1",
            "expires_at" => DateTime.add(DateTime.utc_now(), 300) |> DateTime.to_iso8601(),
            "target_refs" => ["ext-1"]
          },
          inserted_at: ~U[2026-05-10 10:10:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries, action_items)

      assert derived.runbook_title == "Mailglass Recovery"
      assert length(derived.runbook_steps) == 3

      [s1, s2, s3] = derived.runbook_steps
      assert s1.id == "step-1"
      assert s1.state == :guidance
      assert s1.targeting_hints == []

      assert s2.id == "step-2"
      assert s2.state == :previewable
      assert length(s2.targeting_hints) == 1
      assert hd(s2.targeting_hints).id == "ai-1"

      assert s3.id == "step-3"
      assert s3.state == :executable

      assert derived.active_preview.step_id == "step-2"
      assert derived.active_preview.preview_token == "token-1"
    end

    test "marks steps as executed if a mitigation_executed entry exists" do
      incident = %Incident{
        id: "inc-1",
        runbook_data: %{
          "steps" => [%{id: "step-1", label: "Fix it"}]
        }
      }

      entries = [
        %TimelineEntry{
          type: "mitigation_executed",
          payload: %{"step_id" => "step-1"},
          inserted_at: ~U[2026-05-10 10:15:00Z]
        }
      ]

      derived = WorkbenchContract.derive(incident, entries)
      step = hd(derived.runbook_steps)
      assert step.state == :executed
      assert step.executed_at == ~U[2026-05-10 10:15:00Z]
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
