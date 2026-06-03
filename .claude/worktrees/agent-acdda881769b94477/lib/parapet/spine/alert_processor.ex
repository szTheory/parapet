defmodule Parapet.Spine.AlertProcessor do
  @moduledoc """
  Processes alert batches received from webhooks.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
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

  @dialyzer {:nowarn_function, process_firing_alert: 1}
  defp process_firing_alert(alert) do
    repo = Evidence.repo()
    correlation_key = derive_correlation_key(alert)
    existing_incident = open_incident(repo, correlation_key)
    triage_summary = build_triage_summary(alert)
    triage_snapshot = build_triage_snapshot(triage_summary)

    alertname = get_in(alert, ["labels", "alertname"]) || "Unknown Alert"
    title = derive_title(alert, triage_summary, alertname)
    description = get_in(alert, ["annotations", "description"])
    runbook_data = build_runbook_data(alertname, triage_summary)
    current_summary = if(existing_incident, do: Incident.triage_summary(existing_incident))
    new_summary = Map.get(runbook_data, "triage")

    incident_changeset =
      build_incident_changeset(existing_incident, %{
        title: title,
        description: description,
        state: "open",
        correlation_key: correlation_key,
        runbook_data: merge_runbook_data(existing_incident, runbook_data)
      })

    snapshot_required? = is_map(new_summary) and summary_changed?(current_summary, new_summary)

    multi =
      Ecto.Multi.new()
      |> put_incident(existing_incident, incident_changeset)
      |> maybe_insert_triage_snapshot(snapshot_required?, triage_snapshot)
      |> maybe_enqueue_automations(existing_incident)
      |> Ecto.Multi.run(:broadcast, fn _repo, %{incident: incident} ->
        Parapet.Notifier.broadcast(incident)
        {:ok, incident}
      end)

    case repo.transaction(multi) do
      {:ok, %{incident: incident} = result} ->
        if is_nil(existing_incident) do
          correlate_recent_events(incident)
        end

        {:ok, result[:broadcast] || incident}

      error ->
        error
    end
  end

  defp correlate_recent_events(incident) do
    time_threshold = DateTime.add(DateTime.utc_now(), -60, :minute)

    query =
      from(e in Parapet.Spine.SystemEvent,
        where: e.inserted_at >= ^time_threshold
      )

    events = Evidence.repo().all(query)

    Enum.each(events, fn event ->
      changeset =
        TimelineEntry.changeset(%TimelineEntry{}, %{
          incident_id: incident.id,
          type: event.type,
          payload: event.payload
        })

      Evidence.repo().insert(changeset)
    end)
  end

  defp build_runbook_data(alertname, triage_summary) when is_binary(alertname) do
    slo = Enum.find(Parapet.SLO.all(), fn s -> to_string(s.name) == alertname end)

    case slo do
      %{runbook: runbook} when not is_nil(runbook) ->
        module = get_runbook_module(runbook)

        if module && Code.ensure_loaded?(module) &&
             function_exported?(module, :__runbook_schema__, 0) do
          apply(module, :__runbook_schema__, [])
          |> Incident.put_triage_summary(triage_summary)
        else
          Incident.put_triage_summary(%{}, triage_summary)
        end

      _ ->
        Incident.put_triage_summary(%{}, triage_summary)
    end
  end

  defp build_runbook_data(_, triage_summary), do: Incident.put_triage_summary(%{}, triage_summary)

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

  defp open_incident(repo, correlation_key) do
    query =
      from(i in Incident, where: i.correlation_key == ^correlation_key and i.state == "open")

    case repo.all(query) do
      [incident | _] -> incident
      _ -> nil
    end
  end

  defp build_incident_changeset(nil, attrs), do: Incident.changeset(%Incident{}, attrs)

  defp build_incident_changeset(%Incident{} = incident, attrs),
    do: Incident.changeset(incident, attrs)

  @dialyzer {:nowarn_function, put_incident: 3}
  defp put_incident(multi, nil, changeset), do: Ecto.Multi.insert(multi, :incident, changeset)

  defp put_incident(multi, _incident, changeset),
    do: Ecto.Multi.update(multi, :incident, changeset)

  defp maybe_insert_triage_snapshot(multi, false, _snapshot) do
    Ecto.Multi.run(multi, :triage_snapshot, fn _repo, _changes -> {:ok, nil} end)
  end

  defp maybe_insert_triage_snapshot(multi, true, snapshot) do
    Ecto.Multi.insert(multi, :triage_snapshot, fn %{incident: incident} ->
      TimelineEntry.changeset(%TimelineEntry{}, %{
        type: "triage_snapshot",
        payload: snapshot,
        incident_id: incident.id
      })
    end)
  end

  defp maybe_enqueue_automations(multi, existing_incident) do
    if is_nil(existing_incident) do
      worker = Parapet.Automation.Executor
      oban = Oban

      Ecto.Multi.run(multi, :enqueue_automations, fn _repo, %{incident: incident} ->
        steps =
          get_in(incident.runbook_data || %{}, ["steps"]) ||
            get_in(incident.runbook_data || %{}, [:steps]) || []

        Enum.each(steps, fn step ->
          auto_exec = Map.get(step, "auto_execute") || Map.get(step, :auto_execute) || false

          if auto_exec and Code.ensure_loaded?(worker) and Code.ensure_loaded?(oban) and
               function_exported?(oban, :insert!, 1) do
            step_id = Map.get(step, "id") || Map.get(step, :id)

            %{incident_id: incident.id, step_id: to_string(step_id)}
            |> then(&apply(worker, :new, [&1]))
            |> then(&apply(oban, :insert!, [&1]))
          end
        end)

        {:ok, :enqueued}
      end)
    else
      multi
    end
  end

  defp build_triage_summary(alert) do
    labels = Map.get(alert, "labels", %{})
    annotations = Map.get(alert, "annotations", %{})

    summary =
      %{
        "integration" => labels["integration"],
        "symptom" => derive_symptom(labels, annotations),
        "fault_plane" => labels["fault_plane"],
        "impact" => derive_impact(labels, annotations),
        "queue" => labels["queue"],
        "pipeline_stage" => labels["pipeline_stage"],
        "delay_bucket" => labels["delay_bucket"],
        "failure_class" => labels["failure_class"],
        "next_safe_action" => derive_next_safe_action(labels, annotations),
        "confidence" => derive_confidence(labels, annotations)
      }
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        if present_value?(value), do: Map.put(acc, key, value), else: acc
      end)

    if triage_summary?(summary), do: summary, else: nil
  end

  defp build_triage_snapshot(nil), do: nil

  defp build_triage_snapshot(summary),
    do: Map.put(summary, "evidence_facts", derive_evidence_facts(summary))

  defp derive_title(alert, triage_summary, default_alertname) do
    annotations = Map.get(alert, "annotations", %{})

    case triage_summary do
      %{"integration" => integration, "symptom" => symptom}
      when is_binary(integration) and is_binary(symptom) ->
        "#{format_integration(integration)} #{String.downcase(symptom)}"

      _ ->
        annotations["summary"] || default_alertname
    end
  end

  defp derive_symptom(labels, annotations) do
    annotations["parapet_symptom"] ||
      labels["symptom"] ||
      annotations["summary"] ||
      normalize_alertname(labels["alertname"])
  end

  defp derive_impact(labels, annotations) do
    annotations["impact"] ||
      case labels["fault_plane"] do
        "backlog" -> "Queued work is aging beyond the expected freshness window."
        "provider" -> "Provider-side delivery is degrading for real user traffic."
        "suppression" -> "Suppressed delivery attempts may be blocking intended notifications."
        "webhook" -> "Confirmation or callback evidence is delayed after provider handoff."
        "worker" -> "Internal execution is failing before work completes."
        _ -> nil
      end
  end

  defp derive_next_safe_action(labels, annotations) do
    annotations["next_safe_action"] ||
      case labels["fault_plane"] do
        "backlog" -> "Inspect queue depth and worker saturation before retrying jobs."
        "provider" -> "Check provider status and recent bounded failure classes."
        "suppression" -> "Inspect suppression rules and affected exact delivery objects."
        "webhook" -> "Inspect callback ingress, signatures, and reconciliation health."
        "worker" -> "Inspect worker logs and retry posture for the affected queue."
        _ -> nil
      end
  end

  defp derive_confidence(labels, annotations) do
    annotations["confidence"] || labels["confidence"] || "medium"
  end

  defp derive_evidence_facts(summary) do
    [
      fact_if_present(
        summary["fault_plane"],
        &"Fault plane classified as #{&1} from bounded alert metadata."
      ),
      fact_if_present(summary["queue"], &"Queue #{&1} is part of the observed symptom surface."),
      fact_if_present(
        summary["pipeline_stage"],
        &"Pipeline stage #{&1} was present on the alert."
      ),
      fact_if_present(
        summary["delay_bucket"],
        &"Delay bucket #{&1} indicates bounded freshness impact."
      ),
      fact_if_present(
        summary["failure_class"],
        &"Failure class #{&1} is already classified upstream."
      )
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.take(4)
  end

  defp merge_runbook_data(nil, runbook_data), do: runbook_data

  defp merge_runbook_data(%Incident{} = incident, runbook_data),
    do: Map.merge(incident.runbook_data || %{}, runbook_data)

  defp summary_changed?(current_summary, new_summary),
    do: normalize_map(current_summary) != normalize_map(new_summary)

  defp normalize_map(nil), do: %{}

  defp normalize_map(map) when is_map(map),
    do: Enum.into(map, %{}, fn {key, value} -> {to_string(key), value} end)

  defp triage_summary?(summary), do: is_map(summary) and Map.has_key?(summary, "fault_plane")

  defp normalize_alertname(nil), do: nil

  defp normalize_alertname(alertname) when is_binary(alertname) do
    alertname
    |> String.replace(~r/[_-]+/, " ")
    |> String.replace(~r/(?<=.)([A-Z])/, " \\1")
    |> String.downcase()
  end

  defp format_integration(integration) do
    integration
    |> to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp fact_if_present(value, fun) when is_binary(value) and value != "", do: fun.(value)
  defp fact_if_present(_, _fun), do: nil

  defp present_value?(value) when is_binary(value), do: value != ""
  defp present_value?(nil), do: false
  defp present_value?(value), do: value != ""
end
