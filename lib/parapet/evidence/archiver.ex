defmodule Parapet.Evidence.Archiver do
  @moduledoc """
  Archives old, resolved incidents to a JSONL file and deletes them from the primary database.
  """

  import Ecto.Query, only: [from: 2]

  alias Parapet.Spine.Incident

  @default_chunk_size 100

  @spec archive(module(), Path.t(), pos_integer()) :: {:ok, :ok}
  def archive(repo, path, retention_days) when is_integer(retention_days) and retention_days > 0 do
    cutoff =
      DateTime.utc_now()
      |> DateTime.add(-retention_days, :day)
      |> DateTime.truncate(:second)

    File.mkdir_p!(Path.dirname(path))

    repo.transaction(fn ->
      Incident
      |> archive_query(cutoff)
      |> repo.stream(max_rows: chunk_size())
      |> Stream.chunk_every(chunk_size())
      |> Enum.each(fn incidents ->
        full_incidents = repo.preload(incidents, [timeline_entries: :tool_audits])

        jsonl =
          full_incidents
          |> Enum.map(&encode_incident/1)
          |> Enum.join("\n")

        File.write!(path, jsonl <> "\n", [:append, :utf8])

        ids = Enum.map(incidents, & &1.id)
        repo.delete_all(from incident in Incident, where: incident.id in ^ids)
      end)

      :ok
    end)
  end

  defp archive_query(queryable, cutoff) do
    from(
      incident in queryable,
      where: incident.state == "resolved",
      where: incident.inserted_at < ^cutoff
    )
  end

  defp chunk_size do
    Application.get_env(:parapet, :archive_chunk_size, @default_chunk_size)
  end

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
