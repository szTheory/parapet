defmodule Parapet.Spine.AlertProcessor do
  @moduledoc """
  Processes alert batches received from webhooks.
  """

  alias Parapet.Spine.Incident
  alias Parapet.Spine.TimelineEntry
  alias Parapet.Evidence

  import Ecto.Query, only: [from: 2]

  @doc """
  Processes a batch of alerts from the webhook payload.
  """
  def process_batch(payload) do
    if valid_payload?(payload) do
      alerts = Map.get(payload, "alerts", [])

      alerts
      |> Enum.filter(&(&1["status"] == "firing"))
      |> Enum.each(&process_firing_alert/1)

      alerts
      |> Enum.filter(&(&1["status"] == "resolved"))
      |> Enum.each(&process_resolved_alert/1)

      :ok
    else
      {:error, :invalid_payload}
    end
  end

  defp valid_payload?(payload) when is_map(payload) do
    Map.has_key?(payload, "alerts") and is_list(payload["alerts"])
  end

  defp valid_payload?(_), do: false

  defp process_firing_alert(alert) do
    correlation_key = derive_correlation_key(alert)

    alertname = get_in(alert, ["labels", "alertname"]) || "Unknown Alert"
    title = get_in(alert, ["annotations", "summary"]) || alertname

    description = get_in(alert, ["annotations", "description"])

    changeset =
      Incident.changeset(%Incident{}, %{
        title: title,
        description: description,
        state: "open",
        correlation_key: correlation_key
      })

    changeset = attach_runbook_data(changeset, alertname)

    result =
      Evidence.repo().insert(changeset,
        on_conflict: :nothing,
        conflict_target: [:correlation_key]
      )

    case result do
      {:ok, inserted_incident} ->
        incident =
          if inserted_incident.id do
            correlate_recent_events(inserted_incident)
            inserted_incident
          else
            Evidence.repo().get_by!(Incident, correlation_key: correlation_key)
          end

        Parapet.Notifier.broadcast(incident)
        {:ok, incident}

      error ->
        error
    end
  end

  defp correlate_recent_events(incident) do
    time_threshold = DateTime.add(DateTime.utc_now(), -60, :minute)
    
    query = 
      from e in Parapet.Spine.SystemEvent,
        where: e.inserted_at >= ^time_threshold
        
    events = Evidence.repo().all(query)
    
    Enum.each(events, fn event ->
      changeset = TimelineEntry.changeset(%TimelineEntry{}, %{
        incident_id: incident.id,
        type: event.type,
        payload: event.payload
      })
      Evidence.repo().insert(changeset)
    end)
  end

  defp attach_runbook_data(changeset, alertname) when is_binary(alertname) do
    slo = Enum.find(Parapet.SLO.all(), fn s -> to_string(s.name) == alertname end)

    case slo do
      %{runbook: runbook} when not is_nil(runbook) ->
        module = get_runbook_module(runbook)

        if module && Code.ensure_loaded?(module) &&
             function_exported?(module, :__runbook_schema__, 0) do
          Ecto.Changeset.put_change(
            changeset,
            :runbook_data,
            apply(module, :__runbook_schema__, [])
          )
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp attach_runbook_data(changeset, _), do: changeset

  defp get_runbook_module(runbook) when is_atom(runbook), do: runbook

  defp get_runbook_module(runbook) when is_binary(runbook) do
    try do
      String.to_existing_atom(runbook)
    rescue
      ArgumentError -> nil
    end
  end

  defp get_runbook_module(_), do: nil

  @dialyzer {:nowarn_function, process_resolved_alert: 1}
  defp process_resolved_alert(alert) do
    correlation_key = derive_correlation_key(alert)
    repo = Evidence.repo()

    query =
      from(i in Incident, where: i.correlation_key == ^correlation_key and i.state == "open")

    case repo.all(query) do
      [incident | _] ->
        incident_changeset = Incident.changeset(incident, %{state: "resolved"})

        timeline_entry_changeset =
          TimelineEntry.changeset(%TimelineEntry{}, %{
            type: "auto_resolved",
            payload: alert,
            incident_id: incident.id
          })

        multi =
          Ecto.Multi.new()
          |> Ecto.Multi.update(:incident, incident_changeset)
          |> Ecto.Multi.insert(:timeline_entry, timeline_entry_changeset)
          |> Ecto.Multi.run(:broadcast, fn _repo, %{incident: updated_incident} ->
            Parapet.Notifier.broadcast(updated_incident)
            {:ok, updated_incident}
          end)

        repo.transaction(multi)

      _ ->
        # Incident not found or already closed, safe to ignore
        :ok
    end
  end

  defp derive_correlation_key(alert) do
    case Map.get(alert, "fingerprint") do
      nil ->
        labels = Map.get(alert, "labels", %{})
        # Sort labels to ensure deterministic hashing
        encoded =
          labels
          |> Enum.sort()
          |> Enum.map_join(",", fn {k, v} -> "#{k}:#{v}" end)

        :crypto.hash(:sha256, encoded) |> Base.encode16(case: :lower)

      fingerprint ->
        fingerprint
    end
  end
end
