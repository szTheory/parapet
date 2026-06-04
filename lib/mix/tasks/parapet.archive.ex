defmodule Mix.Tasks.Parapet.Archive do
  @shortdoc "Archives old Parapet evidence to JSONL."

  @moduledoc """
  Archives resolved incidents older than the retention window to a JSONL file.

  ## Examples

      mix parapet.archive
      mix parapet.archive --days 30 --path priv/parapet/archive.jsonl
  """

  use Mix.Task

  @default_days 90
  @default_path "priv/parapet/archive.jsonl"

  @impl Mix.Task
  def run(args) do
    Application.load(:parapet)
    Mix.Task.run("app.config")

    {opts, _, _} = OptionParser.parse(args, switches: [days: :integer, path: :string])

    repo = Application.fetch_env!(:parapet, :repo)
    days = Keyword.get(opts, :days, @default_days)
    path = Keyword.get(opts, :path, @default_path)

    case Parapet.Evidence.Archiver.archive(repo, path, days) do
      {:ok, %Parapet.Evidence.Archiver.Summary{} = summary} ->
        Mix.shell().info(Jason.encode!(summary_to_json(summary)))
        :ok

      {:error, %Parapet.Evidence.Archiver.Failure{} = failure} ->
        Mix.raise(failure_message(failure))
    end
  end

  defp summary_to_json(%Parapet.Evidence.Archiver.Summary{} = summary) do
    %{
      status: "ok",
      run_id: summary.run_id,
      path: summary.path,
      manifest_path: summary.manifest_path,
      retention_days: summary.retention_days,
      cutoff: encode_time(summary.cutoff),
      selected_count: summary.selected_count,
      archived_count: summary.archived_count,
      deleted_count: summary.deleted_count,
      skipped_count: summary.skipped_count,
      bytes_written: summary.bytes_written,
      checksum: summary.checksum
    }
  end

  defp failure_message(%Parapet.Evidence.Archiver.Failure{} = failure) do
    summary = failure.partial_summary

    [
      "Archive failed",
      "stage=#{failure.stage}",
      "path=#{failure.path || summary_value(summary, :path)}",
      "run_id=#{failure.run_id || summary_value(summary, :run_id)}",
      "selected=#{summary_value(summary, :selected_count)}",
      "archived=#{summary_value(summary, :archived_count)}",
      "deleted=#{summary_value(summary, :deleted_count)}",
      "manifest_path=#{failure.manifest_path || summary_value(summary, :manifest_path)}",
      "reason=#{inspect(failure.reason)}"
    ]
    |> Enum.join(" ")
  end

  defp summary_value(nil, _field), do: "unknown"
  defp summary_value(summary, field), do: Map.fetch!(summary, field)

  defp encode_time(nil), do: nil
  defp encode_time(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp encode_time(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
end
