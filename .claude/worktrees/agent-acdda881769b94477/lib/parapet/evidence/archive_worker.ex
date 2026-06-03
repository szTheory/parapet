if Code.ensure_loaded?(Oban.Worker) do
  defmodule Parapet.Evidence.ArchiveWorker do
    @moduledoc """
    Optional Oban worker for scheduling Parapet evidence archival.

    > #### Experimental {: .warning}
    >
    > This module is **experimental** in v1.x. Its API may change in a minor release with a
    > single-version notice in CHANGELOG.md. See
    > [Stability & Deprecation Policy](stability.html) for details.
    """

    use Oban.Worker, queue: :default

    @default_days 90
    @default_path "priv/parapet/archive.jsonl"

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      repo = Application.fetch_env!(:parapet, :repo)
      days = Map.get(args, "days", @default_days)
      path = Map.get(args, "path", @default_path)

      Parapet.Evidence.Archiver.archive(repo, path, days)
    end
  end
end
