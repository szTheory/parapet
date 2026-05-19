defmodule Mix.Tasks.Parapet.ArchiveTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Parapet.Archive
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
        incident.state != "open" and DateTime.compare(incident.inserted_at, cutoff) == :lt
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
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("app.config")

    archive_path =
      Path.join(System.tmp_dir!(), "parapet-archive-task-#{System.unique_integer([:positive])}.jsonl")

    old_incident = %Incident{id: Ecto.UUID.generate(), state: "resolved", inserted_at: days_ago(120)}
    recent_incident = %Incident{id: Ecto.UUID.generate(), state: "resolved", inserted_at: days_ago(10)}

    Application.put_env(:parapet, :repo, FakeRepo)
    start_supervised!({FakeRepo, [old_incident, recent_incident]})

    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
      File.rm(archive_path)
    end)

    %{archive_path: archive_path, archived_id: old_incident.id}
  end

  test "parses CLI args, fetches repo from config, invokes the archiver, and prints JSON", %{
    archive_path: archive_path,
    archived_id: archived_id
  } do
    assert :ok = Archive.run(["--days", "90", "--path", archive_path])

    assert_receive {:mix_shell, :info, [output]}

    assert %{"status" => "ok", "result" => "ok"} = Jason.decode!(output)

    snapshot = FakeRepo.snapshot()
    assert snapshot.archived_ids == [archived_id]
    assert snapshot.transactions == 1
    assert snapshot.stream_opts == [[max_rows: 100]]
    assert File.exists?(archive_path)
  end

  test "uses default days and path when no flags are provided" do
    default_path = Path.join(["priv", "parapet", "archive.jsonl"])
    File.rm(default_path)

    on_exit(fn -> File.rm(default_path) end)

    assert :ok = Archive.run([])

    assert_receive {:mix_shell, :info, [output]}
    assert %{"status" => "ok", "result" => "ok"} = Jason.decode!(output)

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
