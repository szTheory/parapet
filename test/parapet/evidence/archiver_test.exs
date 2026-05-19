defmodule Parapet.Evidence.ArchiverTest do
  use ExUnit.Case, async: false

  alias Parapet.Evidence.Archiver
  alias Parapet.Spine.{Incident, TimelineEntry, ToolAudit}

  defmodule FakeRepo do
    use Agent

    def start_link(fixtures) do
      Agent.start_link(fn ->
        %{
          incidents: fixtures,
          archived_ids: [],
          preloads: [],
          stream_calls: [],
          delete_calls: [],
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
        %{current | stream_calls: [%{query: query, opts: opts} | current.stream_calls]}
      end)

      fixtures =
        query
        |> matching_ids_from_query()
        |> then(fn ids ->
          Enum.filter(state.incidents, &(&1.id in ids))
        end)

      Stream.map(fixtures, & &1)
    end

    def preload(incidents, preloads) do
      Agent.update(__MODULE__, fn state ->
        %{state | preloads: [preloads | state.preloads]}
      end)

      incidents
    end

    def delete_all(%Ecto.Query{} = query) do
      ids = ids_from_delete_query(query)

      Agent.get_and_update(__MODULE__, fn state ->
        remaining = Enum.reject(state.incidents, &(&1.id in ids))

        {
          {length(ids), nil},
          %{
            state
            | incidents: remaining,
              archived_ids: state.archived_ids ++ ids,
              delete_calls: [ids | state.delete_calls]
          }
        }
      end)
    end

    def snapshot do
      Agent.get(__MODULE__, & &1)
    end

    defp matching_ids_from_query(query) do
      cutoff = Enum.at(query.wheres, 1).params |> Enum.at(0) |> elem(0)

      Agent.get(__MODULE__, fn state ->
        state.incidents
        |> Enum.filter(fn incident ->
          incident.state != "open" and DateTime.compare(incident.inserted_at, cutoff) == :lt
        end)
        |> Enum.map(& &1.id)
      end)
    end

    defp ids_from_delete_query(query) do
      [{ids, _type}] = Enum.at(query.wheres, 0).params
      ids
    end
  end

  setup do
    old_resolved_audit =
      %ToolAudit{
        id: Ecto.UUID.generate(),
        tool_name: "rerun",
        input: %{"attempt" => 1},
        output: %{"status" => "ok"},
        success: true,
        duration_ms: 12,
        inserted_at: days_ago(45),
        updated_at: days_ago(45)
      }

    old_resolved_timeline =
      %TimelineEntry{
        id: Ecto.UUID.generate(),
        type: "note",
        payload: %{"text" => "resolved"},
        inserted_at: days_ago(45),
        updated_at: days_ago(45)
      }
      |> Map.put(:tool_audits, [old_resolved_audit])

    old_resolved =
      %Incident{
        id: Ecto.UUID.generate(),
        title: "Old resolved incident",
        description: "archive me",
        state: "resolved",
        inserted_at: days_ago(45),
        updated_at: days_ago(45)
      }
      |> Map.put(:timeline_entries, [old_resolved_timeline])

    old_investigating =
      %Incident{
        id: Ecto.UUID.generate(),
        title: "Old investigating incident",
        description: "archive me too",
        state: "investigating",
        inserted_at: days_ago(31),
        updated_at: days_ago(31)
      }
      |> Map.put(:timeline_entries, [])

    recent_resolved =
      %Incident{
        id: Ecto.UUID.generate(),
        title: "Recent resolved incident",
        description: "keep me",
        state: "resolved",
        inserted_at: days_ago(5),
        updated_at: days_ago(5)
      }
      |> Map.put(:timeline_entries, [])

    old_open =
      %Incident{
        id: Ecto.UUID.generate(),
        title: "Old open incident",
        description: "keep me open",
        state: "open",
        inserted_at: days_ago(60),
        updated_at: days_ago(60)
      }
      |> Map.put(:timeline_entries, [])

    Application.put_env(:parapet, :archive_chunk_size, 1)

    start_supervised!({FakeRepo, [old_resolved, old_investigating, recent_resolved, old_open]})

    path =
      Path.join(System.tmp_dir!(), "parapet-archiver-#{System.unique_integer([:positive])}.jsonl")

    on_exit(fn ->
      Application.delete_env(:parapet, :archive_chunk_size)
      File.rm(path)
    end)

    %{archive_path: path, archive_ids: [old_resolved.id, old_investigating.id]}
  end

  test "archives resolved or investigating incidents older than retention, preloads nested evidence, and deletes archived rows",
       %{archive_path: archive_path, archive_ids: archive_ids} do
    assert {:ok, :ok} = Archiver.archive(FakeRepo, archive_path, 30)

    archive_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&Jason.decode!/1)
    |> then(fn lines ->
      assert Enum.map(lines, & &1["id"]) == archive_ids
      assert Enum.map(lines, & &1["state"]) == ["resolved", "investigating"]

      [first | _] = lines
      assert hd(first["timeline_entries"])["tool_audits"] != []
    end)

    snapshot = FakeRepo.snapshot()

    assert snapshot.archived_ids == archive_ids
    assert length(snapshot.delete_calls) == 2
    assert snapshot.preloads == [[timeline_entries: :tool_audits], [timeline_entries: :tool_audits]]
    assert [%{opts: [max_rows: 1]}] = snapshot.stream_calls

    remaining_states = Enum.map(snapshot.incidents, & &1.state)
    assert Enum.sort(remaining_states) == ["open", "resolved"]
  end

  defp days_ago(days) do
    DateTime.utc_now()
    |> DateTime.add(-days, :day)
    |> DateTime.truncate(:second)
  end
end
