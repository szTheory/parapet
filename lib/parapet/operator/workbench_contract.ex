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
    :active_preview
  ]

  @doc """
  Given an Incident and its TimelineEntries, derives the workbench-ready fields.
  Accepts optional action_items for exact targeting hints.
  """
  def derive(%Incident{} = incident, entries, action_items \\ []) when is_list(entries) do
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
      active_preview: find_active_preview(sorted_entries)
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
end
