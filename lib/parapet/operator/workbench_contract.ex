defmodule Parapet.Operator.WorkbenchContract do
  @moduledoc """
  Derives operator-facing fields from the durable evidence spine, ensuring that
  features like severity, journey impact, or mitigation state are computed
  deterministically without modifying the core domain schemas.
  """

  alias Parapet.Spine.Incident

  defstruct [
    :severity,
    :affected_journey,
    :correlated_change,
    :resolved_at,
    :approval_state,
    :recommendation_state
  ]

  @doc """
  Given an Incident and its TimelineEntries, derives the workbench-ready fields.
  """
  def derive(%Incident{} = incident, entries) when is_list(entries) do
    sorted_entries = Enum.sort_by(entries, & &1.inserted_at, {:desc, DateTime})

    summary = find_latest(sorted_entries, ["incident_summary", "triage_snapshot"])
    change = find_latest(sorted_entries, ["change_marker"])
    resolved_event = find_latest(sorted_entries, ["incident_resolved"])

    # State derivations
    approval_state = derive_approval_state(sorted_entries)
    recommendation_state = derive_recommendation_state(sorted_entries)

    resolved_at =
      if resolved_event do
        resolved_event.inserted_at
      else
        if incident.state == "resolved", do: incident.updated_at, else: nil
      end

    %__MODULE__{
      severity: get_in_payload(summary, "severity"),
      affected_journey: get_in_payload(summary, "affected_journey"),
      correlated_change: if(change, do: change.payload, else: nil),
      resolved_at: resolved_at,
      approval_state: approval_state,
      recommendation_state: recommendation_state
    }
  end

  defp find_latest(entries, types) do
    Enum.find(entries, fn e -> e.type in types end)
  end

  defp get_in_payload(nil, _key), do: nil
  defp get_in_payload(entry, key), do: Map.get(entry.payload || %{}, key)

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
