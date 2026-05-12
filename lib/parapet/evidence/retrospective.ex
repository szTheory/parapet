defmodule Parapet.Evidence.Retrospective do
  @moduledoc """
  Generates automated markdown retrospectives from an incident and its timeline.
  """

  alias Parapet.Spine.Incident
  alias Parapet.Evidence

  @doc """
  Generates a Markdown document for an incident by fetching its timeline entries.
  """
  def generate_markdown(%Incident{} = incident) do
    import Ecto.Query

    entries = Evidence.repo().all(
      from t in Parapet.Spine.TimelineEntry,
        where: t.incident_id == ^incident.id,
        order_by: [asc: t.inserted_at]
    )

    generate_markdown(incident, entries)
  end

  def generate_markdown(incident_id) when is_binary(incident_id) do
    incident = Evidence.repo().get!(Incident, incident_id)
    generate_markdown(incident)
  end

  @doc """
  Generates a Markdown document for an incident and its timeline entries.
  """
  def generate_markdown(%Incident{} = incident, entries) when is_list(entries) do
    tta = calculate_tta(incident, entries)
    ttr = calculate_ttr(incident, entries)

    """
    # Incident Retrospective: #{incident.title}

    **State:** #{String.capitalize(incident.state)}
    **Time to Acknowledge:** #{format_duration(tta)}
    **Time to Resolve:** #{format_duration(ttr)}

    ## Description
    #{incident.description}

    ## Timeline Log
    #{format_entries(entries)}
    """
  end

  defp calculate_tta(incident, entries) do
    # TTA = time between incident created and acknowledge entry
    ack_entry = Enum.find(entries, fn entry ->
      entry.type == "acknowledge" or (entry.type == "status_change" and Map.get(entry.payload || %{}, "new_state") == "investigating")
    end)

    if not is_nil(ack_entry) and not is_nil(incident.inserted_at) do
      DateTime.diff(ack_entry.inserted_at, incident.inserted_at, :second)
    else
      nil
    end
  end

  defp calculate_ttr(incident, entries) do
    # TTR = time between incident created and resolved entry
    resolve_entry = Enum.find(entries, fn entry ->
      entry.type == "status_change" and Map.get(entry.payload || %{}, "new_state") == "resolved"
    end)

    end_time = if resolve_entry, do: resolve_entry.inserted_at, else: (List.last(entries) |> then(fn e -> if e, do: e.inserted_at, else: nil end))
    
    if not is_nil(end_time) and not is_nil(incident.inserted_at) do
      DateTime.diff(end_time, incident.inserted_at, :second)
    else
      nil
    end
  end

  defp format_duration(nil), do: "N/A"
  defp format_duration(seconds) when seconds < 60, do: "#{seconds}s"
  defp format_duration(seconds) when seconds < 3600 do
    mins = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{mins}m #{secs}s"
  end
  defp format_duration(seconds) do
    hours = div(seconds, 3600)
    mins = div(rem(seconds, 3600), 60)
    "#{hours}h #{mins}m"
  end

  defp format_entries([]), do: "*No timeline entries found.*"
  defp format_entries(entries) do
    entries
    |> Enum.map(&format_entry/1)
    |> Enum.join("\n")
  end

  defp format_entry(entry) do
    time = if entry.inserted_at do
      Calendar.strftime(entry.inserted_at, "%Y-%m-%d %H:%M:%S UTC")
    else
      "Unknown Time"
    end
    type = format_type(entry.type)
    details = format_payload(entry.payload)

    "- **#{time}** [#{type}] #{details}"
  end

  defp format_type(type) do
    type |> to_string() |> String.replace("_", " ") |> String.capitalize()
  end

  defp format_payload(nil), do: ""
  defp format_payload(payload) when map_size(payload) == 0, do: ""
  defp format_payload(%{"text" => text}), do: text
  defp format_payload(%{"new_state" => state}), do: "State changed to #{state}"
  defp format_payload(%{"change_ref" => ref}), do: "Change marker: #{ref}"
  defp format_payload(payload) do
    inspect(payload)
  end
end
