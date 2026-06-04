defmodule Parapet.Evidence.Archiver do
  @moduledoc """
  Archives old, resolved incidents to a verified JSONL artifact and deletes them from the primary database.

  `archive/3` returns `{:ok, %Parapet.Evidence.Archiver.Summary{}}` when the
  archive artifact, manifest, and exact-id prune complete. It returns
  `{:error, %Parapet.Evidence.Archiver.Failure{}}` when a stage fails, including
  the run paths and partial summary known at the failure point.

  This is an operational export/prune path for Parapet-owned incident evidence,
  not a host backup or restore system. It intentionally does not archive host
  domain rows, external provider records, telemetry samples, Prometheus state,
  Grafana state, or object-store contents.

  Retention currently means resolved incidents created before the cutoff
  (`inserted_at < cutoff`), not incidents resolved before the cutoff. The spine
  schema does not currently store `resolved_at`.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  import Ecto.Query, only: [from: 2]

  alias Parapet.Spine.{ActionClaim, ActionItem, Incident, TimelineEntry, ToolAudit}

  @default_chunk_size 100
  @schema_version 1

  defmodule Summary do
    @moduledoc """
    Structured result for a completed archive run.
    """

    @enforce_keys [
      :status,
      :run_id,
      :schema_version,
      :path,
      :temp_path,
      :manifest_path,
      :retention_days,
      :cutoff,
      :started_at,
      :selected_ids
    ]
    defstruct [
      :status,
      :run_id,
      :schema_version,
      :path,
      :temp_path,
      :manifest_path,
      :retention_days,
      :cutoff,
      :started_at,
      :finished_at,
      :selected_ids,
      selected_count: 0,
      archived_count: 0,
      deleted_count: 0,
      skipped_count: 0,
      counts: %{},
      bytes_written: 0,
      checksum: nil
    ]
  end

  defmodule Failure do
    @moduledoc """
    Structured failure for an archive run.
    """

    @enforce_keys [:status, :stage, :reason, :run_id, :path, :temp_path, :manifest_path]
    defstruct [
      :status,
      :stage,
      :reason,
      :run_id,
      :path,
      :temp_path,
      :manifest_path,
      :partial_summary
    ]
  end

  @type summary :: %Summary{}
  @type failure :: %Failure{}

  @spec archive(module(), Path.t(), pos_integer()) :: {:ok, summary()} | {:error, failure()}
  def archive(repo, path, retention_days)
      when is_integer(retention_days) and retention_days > 0 do
    run_id = configured_run_id() || generate_run_id()
    started_at = configured_now() || DateTime.utc_now()
    started_at = DateTime.truncate(started_at, :second)

    cutoff =
      started_at
      |> DateTime.add(-retention_days, :day)
      |> DateTime.truncate(:second)

    temp_path = temp_path(path, run_id)
    manifest_path = manifest_path(path, run_id)

    initial_summary =
      summary(path, temp_path, manifest_path, retention_days, cutoff, started_at, run_id)

    File.mkdir_p!(Path.dirname(path))

    try do
      repo.transaction(fn ->
        with {:ok, selected_incidents} <- select_incidents(repo, cutoff),
             selected_ids = Enum.map(selected_incidents, & &1.id),
             summary = %{
               initial_summary
               | selected_ids: selected_ids,
                 selected_count: length(selected_ids)
             },
             {:ok, bundles} <- load_bundles(repo, selected_incidents, selected_ids),
             {:ok, summary} <- write_archive(temp_path, bundles, summary),
             {:ok, summary} <- verify_archive(temp_path, summary),
             {:ok, summary} <- publish_archive(temp_path, path, summary),
             {:ok, summary} <- write_manifest(manifest_path, summary),
             {:ok, summary} <- delete_records(repo, selected_ids, summary) do
          {:ok, %{summary | finished_at: DateTime.utc_now() |> DateTime.truncate(:second)}}
        end
      end)
      |> unwrap_transaction()
    rescue
      exception ->
        {:error, failure(:select_records, Exception.message(exception), initial_summary)}
    end
  end

  def archive(_repo, _path, retention_days) do
    raise ArgumentError,
          "retention_days must be a positive integer, got: #{inspect(retention_days)}"
  end

  defp select_incidents(repo, cutoff) do
    incidents =
      Incident
      |> archive_query(cutoff)
      |> repo.stream(max_rows: chunk_size())
      |> Stream.chunk_every(chunk_size())
      |> Enum.flat_map(& &1)

    {:ok, incidents}
  rescue
    exception -> {:error, failure(:select_records, Exception.message(exception), nil)}
  end

  defp archive_query(queryable, cutoff) do
    from(
      incident in queryable,
      where: incident.state == "resolved",
      where: incident.inserted_at < ^cutoff
    )
  end

  defp load_bundles(_repo, [], _selected_ids), do: {:ok, []}

  defp load_bundles(repo, incidents, selected_ids) do
    timeline_entries =
      repo.all(from(entry in TimelineEntry, where: entry.incident_id in ^selected_ids))

    timeline_entry_ids = Enum.map(timeline_entries, & &1.id)

    tool_audits =
      repo.all(from(audit in ToolAudit, where: audit.timeline_entry_id in ^timeline_entry_ids))

    action_items =
      repo.all(from(item in ActionItem, where: item.incident_id in ^selected_ids))

    action_claims =
      repo.all(from(claim in ActionClaim, where: claim.incident_id in ^selected_ids))

    tool_audits_by_timeline = Enum.group_by(tool_audits, & &1.timeline_entry_id)
    timeline_entries_by_incident = Enum.group_by(timeline_entries, & &1.incident_id)
    action_items_by_incident = Enum.group_by(action_items, & &1.incident_id)
    action_claims_by_incident = Enum.group_by(action_claims, & &1.incident_id)

    bundles =
      Enum.map(incidents, fn incident ->
        timeline_entries =
          timeline_entries_by_incident
          |> Map.get(incident.id, [])
          |> Enum.map(fn entry ->
            Map.put(entry, :tool_audits, Map.get(tool_audits_by_timeline, entry.id, []))
          end)

        incident
        |> Map.put(:timeline_entries, timeline_entries)
        |> Map.put(:action_items, Map.get(action_items_by_incident, incident.id, []))
        |> Map.put(:action_claims, Map.get(action_claims_by_incident, incident.id, []))
      end)

    {:ok, bundles}
  rescue
    exception -> {:error, failure(:select_records, Exception.message(exception), nil)}
  end

  defp write_archive(temp_path, bundles, summary) do
    jsonl =
      bundles
      |> Enum.map(&encode_incident/1)
      |> Enum.join("\n")
      |> then(fn
        "" -> ""
        data -> data <> "\n"
      end)

    case file_module().write(temp_path, jsonl, [:write, :utf8]) do
      :ok ->
        {:ok, %{summary | archived_count: length(bundles), counts: count_bundles(bundles)}}

      {:error, reason} ->
        {:error, failure(:write_archive, reason, summary)}
    end
  rescue
    exception -> {:error, failure(:write_archive, Exception.message(exception), summary)}
  end

  defp verify_archive(temp_path, summary) do
    with {:ok, data} <- file_module().read(temp_path),
         {:ok, decoded} <- decode_jsonl(data),
         :ok <- verify_counts(decoded, summary) do
      bytes = byte_size(data)
      checksum = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)

      {:ok, %{summary | bytes_written: bytes, checksum: checksum}}
    else
      {:error, reason} -> {:error, failure(:verify_archive, reason, summary)}
    end
  rescue
    exception -> {:error, failure(:verify_archive, Exception.message(exception), summary)}
  end

  defp publish_archive(temp_path, path, summary) do
    case file_module().rename(temp_path, path) do
      :ok -> {:ok, summary}
      {:error, reason} -> {:error, failure(:publish_archive, reason, summary)}
    end
  rescue
    exception -> {:error, failure(:publish_archive, Exception.message(exception), summary)}
  end

  defp write_manifest(manifest_path, summary) do
    case file_module().write(
           manifest_path,
           Jason.encode!(summary_to_map(summary), pretty: true),
           [
             :write,
             :utf8
           ]
         ) do
      :ok -> {:ok, summary}
      {:error, reason} -> {:error, failure(:write_manifest, reason, summary)}
    end
  rescue
    exception -> {:error, failure(:write_manifest, Exception.message(exception), summary)}
  end

  defp delete_records(_repo, [], summary), do: {:ok, summary}

  defp delete_records(repo, selected_ids, summary) do
    case repo.delete_all(from(incident in Incident, where: incident.id in ^selected_ids)) do
      {deleted_count, _} when deleted_count == length(selected_ids) ->
        {:ok, %{summary | deleted_count: deleted_count}}

      {deleted_count, _} when is_integer(deleted_count) ->
        {:error,
         failure(
           :delete_records,
           {:delete_count_mismatch, expected: length(selected_ids), actual: deleted_count},
           %{summary | deleted_count: deleted_count}
         )}

      {:error, reason} ->
        {:error, failure(:delete_records, reason, summary)}
    end
  rescue
    exception -> {:error, failure(:delete_records, Exception.message(exception), summary)}
  end

  defp decode_jsonl(""), do: {:ok, []}

  defp decode_jsonl(data) do
    data
    |> String.split("\n", trim: true)
    |> Enum.reduce_while({:ok, []}, fn line, {:ok, acc} ->
      case Jason.decode(line) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        {:error, error} -> {:halt, {:error, Exception.message(error)}}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      error -> error
    end
  end

  defp verify_counts(decoded, summary) do
    decoded_counts = count_decoded(decoded)

    cond do
      length(decoded) != summary.archived_count ->
        {:error,
         {:archived_count_mismatch, expected: summary.archived_count, actual: length(decoded)}}

      summary.selected_count != summary.archived_count ->
        {:error,
         {:selected_count_mismatch,
          expected: summary.selected_count, actual: summary.archived_count}}

      decoded_counts != summary.counts ->
        {:error, {:child_count_mismatch, expected: summary.counts, actual: decoded_counts}}

      true ->
        :ok
    end
  end

  defp count_bundles(bundles) do
    %{
      incidents: length(bundles),
      timeline_entries: Enum.sum(Enum.map(bundles, &length(Map.get(&1, :timeline_entries, [])))),
      tool_audits:
        Enum.sum(
          Enum.map(bundles, fn incident ->
            incident
            |> Map.get(:timeline_entries, [])
            |> Enum.map(&length(Map.get(&1, :tool_audits, [])))
            |> Enum.sum()
          end)
        ),
      action_items: Enum.sum(Enum.map(bundles, &length(Map.get(&1, :action_items, [])))),
      action_claims: Enum.sum(Enum.map(bundles, &length(Map.get(&1, :action_claims, []))))
    }
  end

  defp count_decoded(decoded) do
    %{
      incidents: length(decoded),
      timeline_entries: Enum.sum(Enum.map(decoded, &length(Map.get(&1, "timeline_entries", [])))),
      tool_audits:
        Enum.sum(
          Enum.map(decoded, fn incident ->
            incident
            |> Map.get("timeline_entries", [])
            |> Enum.map(&length(Map.get(&1, "tool_audits", [])))
            |> Enum.sum()
          end)
        ),
      action_items: Enum.sum(Enum.map(decoded, &length(Map.get(&1, "action_items", [])))),
      action_claims: Enum.sum(Enum.map(decoded, &length(Map.get(&1, "action_claims", []))))
    }
  end

  defp summary(path, temp_path, manifest_path, retention_days, cutoff, started_at, run_id) do
    %Summary{
      status: :ok,
      run_id: run_id,
      schema_version: @schema_version,
      path: path,
      temp_path: temp_path,
      manifest_path: manifest_path,
      retention_days: retention_days,
      cutoff: cutoff,
      started_at: started_at,
      selected_ids: []
    }
  end

  defp failure(stage, reason, nil) do
    %Failure{
      status: :error,
      stage: stage,
      reason: reason,
      run_id: nil,
      path: nil,
      temp_path: nil,
      manifest_path: nil,
      partial_summary: nil
    }
  end

  defp failure(stage, reason, summary) do
    %Failure{
      status: :error,
      stage: stage,
      reason: reason,
      run_id: summary.run_id,
      path: summary.path,
      temp_path: summary.temp_path,
      manifest_path: summary.manifest_path,
      partial_summary: summary
    }
  end

  defp summary_to_map(%Summary{} = summary) do
    summary
    |> Map.from_struct()
    |> Map.update!(:status, &to_string/1)
    |> normalize_term()
  end

  defp unwrap_transaction({:ok, {:ok, %Summary{} = summary}}), do: {:ok, summary}
  defp unwrap_transaction({:ok, {:error, %Failure{} = failure}}), do: {:error, failure}
  defp unwrap_transaction({:error, %Failure{} = failure}), do: {:error, failure}

  defp unwrap_transaction({:error, reason}) do
    {:error,
     %Failure{
       status: :error,
       stage: :select_records,
       reason: reason,
       run_id: nil,
       path: nil,
       temp_path: nil,
       manifest_path: nil
     }}
  end

  defp chunk_size do
    Application.get_env(:parapet, :archive_chunk_size, @default_chunk_size)
  end

  defp configured_now do
    Application.get_env(:parapet, :archive_now)
  end

  defp configured_run_id do
    Application.get_env(:parapet, :archive_run_id)
  end

  defp file_module do
    Application.get_env(:parapet, :archive_file_module, File)
  end

  defp generate_run_id do
    System.unique_integer([:positive, :monotonic])
    |> Integer.to_string(36)
    |> then(&"archive-#{&1}")
  end

  defp temp_path(path, run_id), do: "#{path}.#{run_id}.tmp"
  defp manifest_path(path, run_id), do: "#{path}.#{run_id}.manifest.json"

  defp encode_incident(incident) do
    incident
    |> normalize_term()
    |> Jason.encode!()
  end

  defp normalize_term(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp normalize_term(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)

  defp normalize_term(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, to_string(key), normalize_term(value))
    end)
  end

  defp normalize_term(list) when is_list(list), do: Enum.map(list, &normalize_term/1)

  defp normalize_term(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      Map.put(acc, to_string(key), normalize_term(value))
    end)
  end

  defp normalize_term(term), do: term
end
