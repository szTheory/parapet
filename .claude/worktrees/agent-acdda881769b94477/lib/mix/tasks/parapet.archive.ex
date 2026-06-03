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

    _result = Parapet.Evidence.Archiver.archive(repo, path, days)

    Mix.shell().info(Jason.encode!(%{status: "ok", result: "ok"}))

    :ok
  end
end
