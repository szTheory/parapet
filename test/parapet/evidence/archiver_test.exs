defmodule Parapet.Evidence.ArchiverTest do
  use ExUnit.Case, async: false

  alias Parapet.Evidence.Archiver
  alias Parapet.Evidence.Archiver.{Failure, Summary}
  alias Parapet.Spine.{ActionClaim, ActionItem, Incident, TimelineEntry, ToolAudit}

  @now ~U[2026-06-04 12:00:00Z]
  @run_id "test-run"

  defmodule FakeRepo do
    use Agent

    def start_link(fixtures) do
      Agent.start_link(
        fn ->
          Map.merge(
            %{
              incidents: [],
              timeline_entries: [],
              tool_audits: [],
              action_items: [],
              action_claims: [],
              archived_ids: [],
              all_calls: [],
              stream_calls: [],
              delete_calls: [],
              delete_result: nil,
              transactions: 0,
              in_transaction?: false
            },
            fixtures
          )
        end,
        name: __MODULE__
      )
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

    def all(%Ecto.Query{} = query) do
      Agent.update(__MODULE__, fn state ->
        %{state | all_calls: [query | state.all_calls]}
      end)

      ids = ids_from_query(query)

      Agent.get(__MODULE__, fn state ->
        case query.from.source do
          {"parapet_timeline_entries", TimelineEntry} ->
            Enum.filter(state.timeline_entries, &(&1.incident_id in ids))

          {"parapet_tool_audits", ToolAudit} ->
            Enum.filter(state.tool_audits, &(&1.timeline_entry_id in ids))

          {"parapet_action_items", ActionItem} ->
            Enum.filter(state.action_items, &(&1.incident_id in ids))

          {"parapet_action_claims", ActionClaim} ->
            Enum.filter(state.action_claims, &(&1.incident_id in ids))
        end
      end)
    end

    def delete_all(%Ecto.Query{} = query) do
      ids = ids_from_query(query)

      Agent.get_and_update(__MODULE__, fn state ->
        delete_result = state.delete_result || {length(ids), nil}

        remaining =
          case delete_result do
            {count, _} when count == length(ids) -> Enum.reject(state.incidents, &(&1.id in ids))
            _ -> state.incidents
          end

        {
          delete_result,
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

    def set_delete_result(result) do
      Agent.update(__MODULE__, &%{&1 | delete_result: result})
    end

    defp matching_ids_from_query(query) do
      cutoff = Enum.at(query.wheres, 1).params |> Enum.at(0) |> elem(0)

      Agent.get(__MODULE__, fn state ->
        state.incidents
        |> Enum.filter(fn incident ->
          incident.state == "resolved" and DateTime.compare(incident.inserted_at, cutoff) == :lt
        end)
        |> Enum.map(& &1.id)
      end)
    end

    defp ids_from_query(query) do
      [{ids, _type}] = Enum.at(query.wheres, 0).params
      ids
    end
  end

  setup do
    Application.put_env(:parapet, :archive_chunk_size, 1)
    Application.put_env(:parapet, :archive_now, @now)
    Application.put_env(:parapet, :archive_run_id, @run_id)

    archived_id = Ecto.UUID.generate()
    boundary_id = Ecto.UUID.generate()
    investigating_id = Ecto.UUID.generate()
    open_id = Ecto.UUID.generate()
    recent_id = Ecto.UUID.generate()

    timeline_entry_id = Ecto.UUID.generate()

    fixtures = %{
      incidents: [
        incident(archived_id, "Old resolved incident", "resolved", DateTime.add(@now, -31, :day)),
        incident(
          boundary_id,
          "Boundary resolved incident",
          "resolved",
          DateTime.add(@now, -30, :day)
        ),
        incident(
          investigating_id,
          "Old investigating incident",
          "investigating",
          DateTime.add(@now, -45, :day)
        ),
        incident(open_id, "Old open incident", "open", DateTime.add(@now, -45, :day)),
        incident(recent_id, "Recent resolved incident", "resolved", DateTime.add(@now, -5, :day))
      ],
      timeline_entries: [
        %TimelineEntry{
          id: timeline_entry_id,
          incident_id: archived_id,
          type: "note",
          payload: %{"text" => "resolved"},
          inserted_at: DateTime.add(@now, -31, :day),
          updated_at: DateTime.add(@now, -31, :day)
        }
      ],
      tool_audits: [
        %ToolAudit{
          id: Ecto.UUID.generate(),
          timeline_entry_id: timeline_entry_id,
          tool_name: "rerun",
          input: %{"attempt" => 1},
          output: %{"status" => "ok"},
          success: true,
          duration_ms: 12,
          inserted_at: DateTime.add(@now, -31, :day),
          updated_at: DateTime.add(@now, -31, :day)
        }
      ],
      action_items: [
        %ActionItem{
          id: Ecto.UUID.generate(),
          incident_id: archived_id,
          title: "Follow up",
          integration: "demo",
          external_id: "item-1",
          kind: "exact_follow_up",
          state: "resolved",
          inserted_at: DateTime.add(@now, -31, :day),
          updated_at: DateTime.add(@now, -31, :day)
        }
      ],
      action_claims: [
        %ActionClaim{
          id: Ecto.UUID.generate(),
          incident_id: archived_id,
          action_kind: "retry_async_item",
          action_key: "retry:item-1",
          status: "executed",
          idempotency_key: "idem-1",
          attempt_count: 1,
          claimed_at: DateTime.add(@now, -31, :day),
          lease_until: DateTime.add(@now, -31, :day),
          finished_at: DateTime.add(@now, -31, :day),
          error_metadata: %{},
          inserted_at: DateTime.add(@now, -31, :day),
          updated_at: DateTime.add(@now, -31, :day)
        }
      ]
    }

    start_supervised!({FakeRepo, fixtures})

    path =
      Path.join(System.tmp_dir!(), "parapet-archiver-#{System.unique_integer([:positive])}.jsonl")

    on_exit(fn ->
      Application.delete_env(:parapet, :archive_chunk_size)
      Application.delete_env(:parapet, :archive_now)
      Application.delete_env(:parapet, :archive_run_id)
      File.rm(path)
      File.rm("#{path}.#{@run_id}.tmp")
      File.rm("#{path}.#{@run_id}.manifest.json")
    end)

    %{
      archive_path: path,
      archived_id: archived_id,
      boundary_id: boundary_id,
      investigating_id: investigating_id,
      open_id: open_id,
      recent_id: recent_id
    }
  end

  test "returns a deterministic Summary and complete bundle for exact selected resolved incidents",
       %{
         archive_path: archive_path,
         archived_id: archived_id,
         boundary_id: boundary_id,
         investigating_id: investigating_id,
         open_id: open_id,
         recent_id: recent_id
       } do
    assert {:ok, %Summary{} = summary} = Archiver.archive(FakeRepo, archive_path, 30)

    assert summary.status == :ok
    assert summary.run_id == @run_id
    assert summary.schema_version == 1
    assert summary.path == archive_path
    assert summary.temp_path == "#{archive_path}.#{@run_id}.tmp"
    assert summary.manifest_path == "#{archive_path}.#{@run_id}.manifest.json"
    assert summary.retention_days == 30
    assert summary.cutoff == DateTime.add(@now, -30, :day)
    assert summary.selected_ids == [archived_id]
    assert summary.selected_count == 1
    assert summary.archived_count == 1
    assert summary.deleted_count == 1
    assert summary.skipped_count == 0

    assert summary.counts == %{
             incidents: 1,
             timeline_entries: 1,
             tool_audits: 1,
             action_items: 1,
             action_claims: 1
           }

    assert summary.bytes_written > 0
    assert is_binary(summary.checksum)
    assert String.length(summary.checksum) == 64

    [archived] =
      archive_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)

    assert archived["id"] == archived_id
    assert archived["state"] == "resolved"
    assert [%{"tool_audits" => [_]}] = archived["timeline_entries"]
    assert [_] = archived["action_items"]
    assert [_] = archived["action_claims"]

    manifest = Jason.decode!(File.read!(summary.manifest_path))
    assert manifest["run_id"] == @run_id
    assert manifest["selected_count"] == 1
    assert manifest["archived_count"] == 1
    assert manifest["deleted_count"] == 0
    assert manifest["bytes_written"] == summary.bytes_written
    assert manifest["checksum"] == summary.checksum

    snapshot = FakeRepo.snapshot()

    assert snapshot.archived_ids == [archived_id]
    assert snapshot.delete_calls == [[archived_id]]
    assert [%{opts: [max_rows: 1]}] = snapshot.stream_calls

    remaining_ids = Enum.map(snapshot.incidents, & &1.id)
    refute archived_id in remaining_ids
    assert boundary_id in remaining_ids
    assert investigating_id in remaining_ids
    assert open_id in remaining_ids
    assert recent_id in remaining_ids
  end

  test "write failure returns Failure without deleting selected records", %{
    archive_path: archive_path
  } do
    directory_path = archive_path <> "-dir"
    File.mkdir_p!(directory_path)

    on_exit(fn -> File.rmdir(directory_path) end)

    assert {:error, %Failure{} = failure} = Archiver.archive(FakeRepo, directory_path, 30)

    assert failure.status == :error
    assert failure.stage in [:write_archive, :publish_archive]
    assert failure.partial_summary.selected_count == 1
    assert FakeRepo.snapshot().delete_calls == []
  end

  test "delete failure keeps published artifact and reports partial summary", %{
    archive_path: archive_path
  } do
    FakeRepo.set_delete_result({0, nil})

    assert {:error, %Failure{} = failure} = Archiver.archive(FakeRepo, archive_path, 30)

    assert failure.stage == :delete_records
    assert {:delete_count_mismatch, [expected: 1, actual: 0]} = failure.reason
    assert failure.partial_summary.path == archive_path
    assert failure.partial_summary.manifest_path == "#{archive_path}.#{@run_id}.manifest.json"
    assert failure.partial_summary.selected_count == 1
    assert failure.partial_summary.archived_count == 1
    assert failure.partial_summary.deleted_count == 0
    assert File.exists?(archive_path)
    assert File.exists?(failure.partial_summary.manifest_path)
  end

  defp incident(id, title, state, inserted_at) do
    %Incident{
      id: id,
      title: title,
      description: title,
      state: state,
      inserted_at: DateTime.truncate(inserted_at, :second),
      updated_at: DateTime.truncate(inserted_at, :second)
    }
  end
end
