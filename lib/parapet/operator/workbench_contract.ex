defmodule Parapet.Operator.WorkbenchContract do
  @moduledoc """
  Derives operator-facing fields from the durable evidence spine, ensuring that
  features like severity, journey impact, or mitigation state are computed
  deterministically without modifying the core domain schemas.
  """

  alias Parapet.Spine.Incident

  defstruct [
    :integration,
    :symptom,
    :fault_plane,
    :impact,
    :next_safe_action,
    :confidence,
    :evidence_facts,
    :classification_updated_at,
    :severity,
    :affected_journey,
    :correlated_change,
    :resolved_at,
    :approval_state,
    :recommendation_state,
    :runbook_title,
    :runbook_description,
    :runbook_steps,
    :active_preview,
    :escalation_summary,
    :timeline_presentations
  ]

  @doc """
  Given an Incident and its TimelineEntries, derives the workbench-ready fields.
  Accepts optional action_items for exact targeting hints.
  """
  def derive(%Incident{} = incident, entries, action_items \\ []) when is_list(entries) do
    timeline_presentations = Enum.map(entries, &timeline_presentation/1)
    sorted_entries = Enum.sort_by(entries, & &1.inserted_at, {:desc, DateTime})

    triage_summary = Incident.triage_summary(incident) || %{}
    snapshot = find_latest(sorted_entries, ["triage_snapshot"])
    triage_payload = build_triage_payload(triage_summary, snapshot)
    change = find_latest(sorted_entries, ["change_marker"])
    resolved_event = find_latest(sorted_entries, ["incident_resolved"])

    approval_state = derive_approval_state(sorted_entries)
    recommendation_state = derive_recommendation_state(sorted_entries)

    resolved_at =
      if resolved_event do
        resolved_event.inserted_at
      else
        if incident.state == "resolved", do: incident.updated_at, else: nil
      end

    runbook_data = incident.runbook_data || %{}
    runbook_title = Map.get(runbook_data, "title") || Map.get(runbook_data, :title)
    runbook_description = Map.get(runbook_data, "description") || Map.get(runbook_data, :description)
    raw_steps = Map.get(runbook_data, "steps") || Map.get(runbook_data, :steps) || []

    %__MODULE__{
      integration: Map.get(triage_payload, "integration"),
      symptom: Map.get(triage_payload, "symptom"),
      fault_plane: Map.get(triage_payload, "fault_plane"),
      impact: Map.get(triage_payload, "impact"),
      next_safe_action: Map.get(triage_payload, "next_safe_action"),
      confidence: Map.get(triage_payload, "confidence"),
      evidence_facts: Map.get(triage_payload, "evidence_facts", []),
      classification_updated_at: if(snapshot, do: snapshot.inserted_at, else: nil),
      severity: Map.get(triage_payload, "severity"),
      affected_journey: Map.get(triage_payload, "affected_journey"),
      correlated_change: if(change, do: change.payload, else: nil),
      resolved_at: resolved_at,
      approval_state: approval_state,
      recommendation_state: recommendation_state,
      runbook_title: runbook_title,
      runbook_description: runbook_description,
      runbook_steps: derive_runbook_steps(raw_steps, sorted_entries, action_items),
      active_preview: find_active_preview(sorted_entries),
      escalation_summary: derive_escalation_summary(incident, sorted_entries),
      timeline_presentations: timeline_presentations
    }
  end

  defp find_latest(entries, types) do
    Enum.find(entries, fn e -> e.type in types end)
  end

  defp derive_runbook_steps(raw_steps, entries, action_items) do
    Enum.map(raw_steps, fn step ->
      step = stringify_keys(step)
      step_id = Map.get(step, "id")

      # Check if this step was executed
      executed_entry =
        Enum.find(entries, fn e ->
          e.type == "mitigation_executed" and
            Map.get(e.payload || %{}, "step_id") == to_string(step_id)
        end)

      # Determine state
      state =
        cond do
          executed_entry -> :executed
          Map.get(step, "preview_only") == true -> :guidance
          Map.get(step, "requires_preview") == true -> :previewable
          true -> :executable
        end

      # Targeting hints
      target_kind = Map.get(step, "target_kind")

      targeting_hints =
        action_items
        |> Enum.filter(fn ai -> to_string(ai.kind) == to_string(target_kind) end)
        |> Enum.map(fn ai ->
          %{id: ai.id, title: ai.title, external_id: ai.external_id, kind: ai.kind}
        end)

      %{
        id: step_id,
        label: Map.get(step, "label"),
        description: Map.get(step, "description"),
        type: Map.get(step, "type"),
        kind: Map.get(step, "kind"),
        capability: Map.get(step, "capability"),
        target_kind: target_kind,
        guidance: Map.get(step, "guidance"),
        state: state,
        executed_at: if(executed_entry, do: executed_entry.inserted_at),
        targeting_hints: targeting_hints
      }
    end)
  end

  defp find_active_preview(entries) do
    # newest "recovery_preview"
    preview = Enum.find(entries, fn e -> e.type == "recovery_preview" end)

    case preview do
      nil ->
        nil

      entry ->
        payload = entry.payload || %{}
        expires_at_raw = Map.get(payload, "expires_at")

        expires_at =
          case expires_at_raw do
            %DateTime{} = dt ->
              dt

            str when is_binary(str) ->
              case DateTime.from_iso8601(str) do
                {:ok, dt, _} -> dt
                _ -> nil
              end

            _ ->
              nil
          end

        if expires_at && DateTime.compare(expires_at, DateTime.utc_now()) == :gt do
          %{
            step_id: Map.get(payload, "step_id"),
            preview_token: Map.get(payload, "preview_token"),
            target_refs: Map.get(payload, "target_refs"),
            expires_at: expires_at,
            data: payload
          }
        else
          nil
        end
    end
  end

  defp build_triage_payload(summary, snapshot) do
    snapshot_payload =
      case snapshot do
        nil -> %{}
        entry -> stringify_keys(entry.payload || %{})
      end

    summary
    |> stringify_keys()
    |> Map.merge(snapshot_payload, fn
      "evidence_facts", _summary_value, snapshot_value -> snapshot_value
      _key, summary_value, _snapshot_value -> summary_value
    end)
    |> ensure_evidence_facts()
  end

  defp ensure_evidence_facts(payload) do
    case Map.get(payload, "evidence_facts") do
      facts when is_list(facts) -> payload
      _ -> Map.put(payload, "evidence_facts", [])
    end
  end

  defp stringify_keys(nil), do: %{}

  defp stringify_keys(map) when is_map(map) do
    Enum.into(map, %{}, fn {key, value} -> {to_string(key), value} end)
  end

  defp derive_approval_state(entries) do
    # Looking for newest "approval_decided" or "approval_requested"
    latest_approval =
      Enum.find(entries, fn e -> e.type in ["approval_decided", "approval_requested"] end)

    case latest_approval do
      nil -> :none
      %{type: "approval_decided", payload: %{"state" => "approved"}} -> :approved
      %{type: "approval_decided", payload: %{"state" => "rejected"}} -> :rejected
      %{type: "approval_requested"} -> :pending
      _ -> :none
    end
  end

  defp derive_recommendation_state(entries) do
    latest_rec = Enum.find(entries, fn e -> e.type == "recommendation" end)

    case latest_rec do
      nil -> :none
      %{payload: %{"state" => state}} when is_binary(state) -> String.to_existing_atom(state)
      _ -> :none
    end
  rescue
    # in case the string isn't an existing atom
    ArgumentError -> :none
  end

  defp derive_escalation_summary(%Incident{} = incident, sorted_entries) do
    escalation_state = escalation_command_state(incident)
    latest_event = latest_escalation_event(sorted_entries)
    suppression = suppression_projection(escalation_state)
    pending_trigger? = pending_trigger?(escalation_state, latest_event, suppression)
    system_action = derive_system_action(sorted_entries)

    %{
      status: escalation_status(suppression, pending_trigger?, latest_event),
      pending_trigger?: pending_trigger?,
      suppression: suppression,
      next_step: derive_next_step(suppression, pending_trigger?, escalation_state, latest_event),
      latest_event: project_latest_event(latest_event),
      system_action: system_action
    }
  end

  defp escalation_command_state(%Incident{runbook_data: runbook_data}) when is_map(runbook_data) do
    case Map.get(runbook_data, "escalation") || Map.get(runbook_data, :escalation) do
      escalation when is_map(escalation) -> stringify_keys(escalation)
      _ -> %{}
    end
  end

  defp escalation_command_state(_incident), do: %{}

  defp latest_escalation_event(entries) do
    find_latest(entries, [
      "escalation_trigger_requested",
      "escalation_suppressed",
      "escalation_short_circuited",
      "escalation_executed"
    ])
  end

  defp suppression_projection(escalation_state) do
    suppressed_until = to_datetime(Map.get(escalation_state, "suppressed_until"))
    active? = match?(%DateTime{}, suppressed_until) and DateTime.compare(suppressed_until, DateTime.utc_now()) == :gt

    %{
      active?: active?,
      until: suppressed_until,
      actor: Map.get(escalation_state, "suppressed_by"),
      reason: Map.get(escalation_state, "suppression_reason")
    }
  end

  defp pending_trigger?(escalation_state, latest_event, suppression) do
    pending_trigger? = Map.get(escalation_state, "pending_trigger") == true
    trigger_requested_at = to_datetime(Map.get(escalation_state, "trigger_requested_at"))

    blocked_by_newer_event? =
      match?(%DateTime{}, trigger_requested_at) and match?(%{inserted_at: %DateTime{}}, latest_event) and
        DateTime.compare(latest_event.inserted_at, trigger_requested_at) in [:eq, :gt] and
        latest_event.type in ["escalation_executed", "escalation_short_circuited", "escalation_suppressed"]

    pending_trigger? and not suppression.active? and not blocked_by_newer_event?
  end

  defp escalation_status(%{active?: true}, _pending_trigger?, _latest_event), do: :suppressed
  defp escalation_status(_suppression, true, _latest_event), do: :manual_trigger_requested
  defp escalation_status(_suppression, _pending_trigger?, %{type: "escalation_executed"}), do: :recently_executed

  defp escalation_status(_suppression, _pending_trigger?, %{type: "escalation_short_circuited"}) do
    :recently_short_circuited
  end

  defp escalation_status(_suppression, _pending_trigger?, _latest_event), do: :idle

  defp derive_next_step(%{active?: true, until: suppressed_until}, _pending_trigger?, _state, _latest_event) do
    %{kind: :await_suppression_expiry, at: suppressed_until, derived?: true}
  end

  defp derive_next_step(_suppression, true, escalation_state, _latest_event) do
    %{kind: :await_worker_execution, at: to_datetime(Map.get(escalation_state, "trigger_requested_at")), derived?: true}
  end

  defp derive_next_step(_suppression, _pending_trigger?, _state, latest_event) do
    %{kind: :monitor_timeline, at: if(latest_event, do: latest_event.inserted_at), derived?: true}
  end

  defp project_latest_event(nil), do: nil

  defp project_latest_event(entry) do
    presentation = timeline_presentation(entry)

    %{
      type: entry.type,
      at: entry.inserted_at,
      actor_class: presentation.actor_class,
      mode: event_payload_value(entry, "mode"),
      reason: event_payload_value(entry, "reason")
    }
  end

  defp derive_system_action(entries) do
    system_entry =
      Enum.find(entries, fn entry ->
        timeline_presentation(entry).system_action?
      end)

    case system_entry do
      nil ->
        %{status: :none, at: nil, mode: nil, derived?: true, recent?: false}

      %{type: "escalation_short_circuited"} = entry ->
        %{
          status: :short_circuited,
          at: entry.inserted_at,
          mode: event_payload_value(entry, "mode"),
          derived?: true,
          recent?: true
        }

      entry ->
        %{
          status: :executed,
          at: entry.inserted_at,
          mode: event_payload_value(entry, "mode") || fallback_system_mode(entry.type),
          derived?: true,
          recent?: true
        }
    end
  end

  defp fallback_system_mode("mitigation_executed"), do: "runbook"
  defp fallback_system_mode(_type), do: nil

  defp timeline_presentation(entry) do
    actor = event_payload_value(entry, "actor")

    cond do
      entry.type == "external_link" ->
        %{actor_class: :external, style_variant: :external_reference, system_action?: false}

      explicit_system_event?(entry) or system_actor?(actor) ->
        %{actor_class: :system, style_variant: :system_action, system_action?: true}

      copilot_actor?(actor) ->
        %{actor_class: :copilot, style_variant: :copilot_action, system_action?: false}

      operator_actor?(actor) ->
        %{actor_class: :operator, style_variant: :operator_action, system_action?: false}

      true ->
        %{actor_class: :evidence, style_variant: :neutral_evidence, system_action?: false}
    end
  end

  defp explicit_system_event?(%{type: type}),
    do: type in ["escalation_executed", "escalation_short_circuited"]

  defp system_actor?(actor) when is_binary(actor), do: String.starts_with?(actor, "system:")
  defp system_actor?(_actor), do: false

  defp copilot_actor?(actor) when is_binary(actor) do
    String.starts_with?(actor, "ai:") or String.starts_with?(actor, "copilot:")
  end

  defp copilot_actor?(_actor), do: false

  defp operator_actor?(actor) when is_binary(actor), do: actor != ""
  defp operator_actor?(_actor), do: false

  defp event_payload_value(%{payload: payload}, key) when is_map(payload) do
    Map.get(payload, key) || Map.get(payload, String.to_atom(key))
  end

  defp event_payload_value(_entry, _key), do: nil

  defp to_datetime(%DateTime{} = value), do: value

  defp to_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp to_datetime(_value), do: nil
end
