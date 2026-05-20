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

    runbook_description =
      Map.get(runbook_data, "description") || Map.get(runbook_data, :description)

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

  @doc """
  Projects a bounded queue row from the durable incident record only.
  Queue rows intentionally omit detail-only evidence and timeline-rich fields.
  """
  def queue_row(%Incident{} = incident) do
    triage = incident |> Incident.triage_summary() |> stringify_keys()
    runbook_data = stringify_keys(incident.runbook_data || %{})

    %{
      incident_id: incident.id,
      state: incident.state,
      title: queue_title(incident, triage),
      severity: Map.get(triage, "severity") || Map.get(runbook_data, "severity"),
      secondary_line: queue_secondary_line(triage, runbook_data),
      updated_at: incident.updated_at,
      updated_at_label: queue_updated_at_label(incident.updated_at),
      attention_chip: queue_attention_chip(runbook_data)
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
    escalation_chain = derive_escalation_chain(escalation_state)
    next_step = derive_next_step(suppression, pending_trigger?, escalation_state, latest_event)

    %{
      status: escalation_status(suppression, pending_trigger?, latest_event),
      pending_trigger?: pending_trigger?,
      suppression: suppression,
      next_step: next_step,
      escalation_chain: escalation_chain,
      time_until_next_escalation: derive_time_until_next_escalation(next_step),
      latest_event: project_latest_event(latest_event),
      system_action: system_action
    }
  end

  defp escalation_command_state(%Incident{runbook_data: runbook_data})
       when is_map(runbook_data) do
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

    active? =
      match?(%DateTime{}, suppressed_until) and
        DateTime.compare(suppressed_until, DateTime.utc_now()) == :gt

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
      match?(%DateTime{}, trigger_requested_at) and
        match?(%{inserted_at: %DateTime{}}, latest_event) and
        DateTime.compare(latest_event.inserted_at, trigger_requested_at) in [:eq, :gt] and
        latest_event.type in [
          "escalation_executed",
          "escalation_short_circuited",
          "escalation_suppressed"
        ]

    pending_trigger? and not suppression.active? and not blocked_by_newer_event?
  end

  defp escalation_status(%{active?: true}, _pending_trigger?, _latest_event), do: :suppressed
  defp escalation_status(_suppression, true, _latest_event), do: :manual_trigger_requested

  defp escalation_status(_suppression, _pending_trigger?, %{type: "escalation_executed"}),
    do: :recently_executed

  defp escalation_status(_suppression, _pending_trigger?, %{type: "escalation_short_circuited"}) do
    :recently_short_circuited
  end

  defp escalation_status(_suppression, _pending_trigger?, _latest_event), do: :idle

  defp derive_next_step(
         %{active?: true, until: suppressed_until},
         _pending_trigger?,
         _state,
         _latest_event
       ) do
    %{kind: :await_suppression_expiry, at: suppressed_until, derived?: true}
  end

  defp derive_next_step(_suppression, true, escalation_state, _latest_event) do
    %{
      kind: :await_worker_execution,
      at: to_datetime(Map.get(escalation_state, "trigger_requested_at")),
      derived?: true
    }
  end

  defp derive_next_step(_suppression, _pending_trigger?, escalation_state, latest_event) do
    next_escalation_at = to_datetime(Map.get(escalation_state, "next_escalation_at"))

    if match?(%DateTime{}, next_escalation_at) do
      %{kind: :await_next_escalation, at: next_escalation_at, derived?: true}
    else
      %{
        kind: :monitor_timeline,
        at: if(latest_event, do: latest_event.inserted_at),
        derived?: true
      }
    end
  end

  defp derive_escalation_chain(escalation_state) do
    current_step_id =
      Map.get(escalation_state, "current_step_id") ||
        Map.get(escalation_state, "next_step_id") ||
        Map.get(escalation_state, "active_step")

    steps =
      escalation_state
      |> Map.get("chain", [])
      |> List.wrap()
      |> Enum.map(&project_escalation_chain_step(&1, current_step_id))

    if steps == [], do: nil, else: steps
  end

  defp project_escalation_chain_step(step, current_step_id) when is_map(step) do
    step = stringify_keys(step)
    id = Map.get(step, "id") || Map.get(step, "key") || Map.get(step, "label")
    status = project_chain_status(step, id, current_step_id)

    %{
      id: id,
      label: Map.get(step, "label") || humanize_chain_id(id),
      delay: Map.get(step, "delay") || Map.get(step, "after"),
      status: status
    }
  end

  defp project_escalation_chain_step(step, current_step_id)
       when is_binary(step) or is_atom(step) do
    project_escalation_chain_step(%{"id" => to_string(step)}, current_step_id)
  end

  defp project_escalation_chain_step(step, _current_step_id) do
    %{
      id: inspect(step),
      label: inspect(step),
      delay: nil,
      status: :pending
    }
  end

  defp project_chain_status(step, id, current_step_id) do
    cond do
      is_binary(Map.get(step, "status")) ->
        Map.get(step, "status") |> normalize_chain_status()

      present_step_id?(id) and present_step_id?(current_step_id) and id == current_step_id ->
        :current

      true ->
        :pending
    end
  end

  defp normalize_chain_status("completed"), do: :completed
  defp normalize_chain_status("sent"), do: :completed
  defp normalize_chain_status("active"), do: :current
  defp normalize_chain_status("current"), do: :current
  defp normalize_chain_status("pending"), do: :pending
  defp normalize_chain_status(_), do: :pending

  defp derive_time_until_next_escalation(%{at: %DateTime{} = at, kind: kind})
       when kind in [:await_suppression_expiry, :await_next_escalation] do
    seconds = DateTime.diff(at, DateTime.utc_now(), :second)

    if seconds > 0 do
      %{seconds: seconds, at: at, derived?: true}
    else
      nil
    end
  end

  defp derive_time_until_next_escalation(_next_step), do: nil

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

  defp queue_title(%Incident{title: title}, %{"symptom" => symptom})
       when is_binary(symptom) and symptom != "" and is_binary(title) and title != "" do
    symptom
  end

  defp queue_title(_incident, %{"symptom" => symptom}) when is_binary(symptom) and symptom != "" do
    symptom
  end

  defp queue_title(%Incident{title: title}, _triage) when is_binary(title) and title != "" do
    title
  end

  defp queue_title(%Incident{id: id}, _triage), do: id

  defp queue_secondary_line(triage, runbook_data) do
    triage
    |> queue_secondary_parts(runbook_data)
    |> Enum.take(2)
    |> Enum.join(" • ")
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp queue_secondary_parts(triage, runbook_data) do
    [
      Map.get(triage, "integration"),
      Map.get(triage, "fault_plane"),
      Map.get(triage, "affected_journey") || Map.get(runbook_data, "affected_journey"),
      Map.get(triage, "queue")
    ]
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
  end

  defp queue_attention_chip(runbook_data) do
    cond do
      is_map(Map.get(runbook_data, "correlated_change")) -> "Correlated change"
      approval_pending?(runbook_data) -> "Approval pending"
      escalation_waiting?(runbook_data) -> "Escalation waiting"
      true -> nil
    end
  end

  defp approval_pending?(runbook_data) do
    case Map.get(runbook_data, "approval") do
      %{"state" => "pending"} -> true
      _ -> Map.get(runbook_data, "approval_state") == "pending"
    end
  end

  defp escalation_waiting?(runbook_data) do
    case Map.get(runbook_data, "escalation") do
      escalation when is_map(escalation) ->
        escalation = stringify_keys(escalation)
        Map.get(escalation, "pending_trigger") == true or
          is_binary(Map.get(escalation, "current_step_id")) or
          match?(%DateTime{}, to_datetime(Map.get(escalation, "next_escalation_at")))

      _ ->
        false
    end
  end

  defp queue_updated_at_label(%DateTime{} = updated_at) do
    seconds = max(DateTime.diff(DateTime.utc_now(), updated_at, :second), 0)

    cond do
      seconds < 60 -> "#{seconds}s ago"
      seconds < 3_600 -> "#{div(seconds, 60)}m ago"
      true -> "#{div(seconds, 3_600)}h ago"
    end
  end

  defp queue_updated_at_label(_updated_at), do: "Updated recently"

  defp present_step_id?(value) when is_binary(value), do: value != ""
  defp present_step_id?(_value), do: false

  defp humanize_chain_id(nil), do: "Unknown step"

  defp humanize_chain_id(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> String.capitalize()
  end
end
