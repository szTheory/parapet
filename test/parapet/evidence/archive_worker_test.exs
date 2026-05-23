if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Evidence.ArchiveWorkerTest do
    use ExUnit.Case, async: false

    alias Parapet.Evidence.ArchiveWorker
    alias Parapet.Spine.Incident

    defmodule FakeRepo do
      use Agent

      def start_link(fixtures) do
        Agent.start_link(fn ->
          %{
            incidents: fixtures,
            archived_ids: [],
            stream_opts: [],
            transactions: 0,
            in_transaction?: false
          }
        end, name: __MODULE__)
      end

      def transaction(fun) when is_function(fun, 0) do
        Agent.update(__MODULE__, fn state ->
          %{state | in_transaction?: true, transactions: state.transactions + 1}
        end)

        result =
          try do
            {:ok, fun.()}
          after
            Agent.update(__MODULE__, &%{&1 | in_transaction?: false})
          end

        result
      end

      def stream(%Ecto.Query{} = query, opts) do
        state = Agent.get(__MODULE__, & &1)

        unless state.in_transaction? do
          raise "expected stream/2 to run inside transaction/1"
        end

        Agent.update(__MODULE__, fn current ->
          %{current | stream_opts: [opts | current.stream_opts]}
        end)

        cutoff = Enum.at(query.wheres, 1).params |> Enum.at(0) |> elem(0)

        state.incidents
        |> Enum.filter(fn incident ->
          incident.state == "resolved" and DateTime.compare(incident.inserted_at, cutoff) == :lt
        end)
        |> Stream.map(& &1)
      end

      def preload(incidents, _preloads), do: incidents

      def delete_all(%Ecto.Query{} = query) do
        [{ids, _type}] = Enum.at(query.wheres, 0).params

        Agent.update(__MODULE__, fn state ->
          remaining = Enum.reject(state.incidents, &(&1.id in ids))
          %{state | incidents: remaining, archived_ids: state.archived_ids ++ ids}
        end)

        {length(ids), nil}
      end

      def snapshot do
        Agent.get(__MODULE__, & &1)
      end
    end

    setup do
      archive_path =
        Path.join(
          System.tmp_dir!(),
          "parapet-archive-worker-#{System.unique_integer([:positive])}.jsonl"
        )

      old_incident = %Incident{id: Ecto.UUID.generate(), state: "resolved", inserted_at: days_ago(120)}
      old_investigating = %Incident{id: Ecto.UUID.generate(), state: "investigating", inserted_at: days_ago(120)}
      recent_incident = %Incident{id: Ecto.UUID.generate(), state: "resolved", inserted_at: days_ago(10)}

      Application.put_env(:parapet, :repo, FakeRepo)
      start_supervised!({FakeRepo, [old_incident, old_investigating, recent_incident]})

      on_exit(fn ->
        Application.delete_env(:parapet, :repo)
        File.rm(archive_path)
      end)

      %{archive_path: archive_path, archived_id: old_incident.id, investigating_id: old_investigating.id}
    end

    test "defines an Oban worker" do
      changeset = ArchiveWorker.new(%{"days" => 90})
      assert Ecto.Changeset.get_change(changeset, :worker) == "Parapet.Evidence.ArchiveWorker"
    end

    test "archives using explicit job args", %{archive_path: archive_path, archived_id: archived_id, investigating_id: investigating_id} do
      job = %Oban.Job{args: %{"days" => 90, "path" => archive_path}}

      assert {:ok, :ok} = ArchiveWorker.perform(job)

      snapshot = FakeRepo.snapshot()
      assert snapshot.archived_ids == [archived_id]
      assert snapshot.transactions == 1
      assert File.exists?(archive_path)
      assert snapshot.stream_opts == [[max_rows: 100]]
      assert Enum.any?(snapshot.incidents, &(&1.id == investigating_id and &1.state == "investigating"))
    end

    test "uses default job args when absent" do
      default_path = Path.join(["priv", "parapet", "archive.jsonl"])
      File.rm(default_path)

      on_exit(fn -> File.rm(default_path) end)

      assert {:ok, :ok} = ArchiveWorker.perform(%Oban.Job{args: %{}})

      snapshot = FakeRepo.snapshot()
      assert length(snapshot.archived_ids) == 1
      assert File.exists?(default_path)
    end

    defp days_ago(days) do
      DateTime.utc_now()
      |> DateTime.add(-days, :day)
      |> DateTime.truncate(:second)
    end
  end
else
  defmodule Parapet.Evidence.ArchiveWorkerTest do
    use ExUnit.Case, async: true

    test "Oban is unavailable, so the worker is not compiled" do
      refute Code.ensure_loaded?(Parapet.Evidence.ArchiveWorker)
    end
  end
end
