if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Evidence.ArchiveWorkerTest do
    use ExUnit.Case, async: false

    alias Parapet.Evidence.Archiver.{Failure, Summary}
    alias Parapet.Evidence.ArchiveWorker
    alias Parapet.Spine.{ActionClaim, ActionItem, Incident, TimelineEntry, ToolAudit}

    @now ~U[2026-06-04 12:00:00Z]
    @run_id "worker-run"

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
                stream_opts: [],
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
          %{current | stream_opts: [opts | current.stream_opts]}
        end)

        cutoff = Enum.at(query.wheres, 1).params |> Enum.at(0) |> elem(0)

        state.incidents
        |> Enum.filter(fn incident ->
          incident.state == "resolved" and DateTime.compare(incident.inserted_at, cutoff) == :lt
        end)
        |> Stream.map(& &1)
      end

      def all(%Ecto.Query{} = query) do
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
              {count, _} when count == length(ids) ->
                Enum.reject(state.incidents, &(&1.id in ids))

              _ ->
                state.incidents
            end

          {
            delete_result,
            %{state | incidents: remaining, archived_ids: state.archived_ids ++ ids}
          }
        end)
      end

      def snapshot do
        Agent.get(__MODULE__, & &1)
      end

      def set_delete_result(result) do
        Agent.update(__MODULE__, &%{&1 | delete_result: result})
      end

      defp ids_from_query(query) do
        [{ids, _type}] = Enum.at(query.wheres, 0).params
        ids
      end
    end

    setup do
      Application.put_env(:parapet, :archive_now, @now)
      Application.put_env(:parapet, :archive_run_id, @run_id)
      Application.put_env(:parapet, :repo, FakeRepo)

      archive_path =
        Path.join(
          System.tmp_dir!(),
          "parapet-archive-worker-#{System.unique_integer([:positive])}.jsonl"
        )

      archived_id = Ecto.UUID.generate()
      timeline_entry_id = Ecto.UUID.generate()

      fixtures = %{
        incidents: [
          incident(archived_id, "resolved", DateTime.add(@now, -120, :day)),
          incident(Ecto.UUID.generate(), "investigating", DateTime.add(@now, -120, :day)),
          incident(Ecto.UUID.generate(), "resolved", DateTime.add(@now, -10, :day))
        ],
        timeline_entries: [
          %TimelineEntry{
            id: timeline_entry_id,
            incident_id: archived_id,
            type: "note",
            payload: %{"text" => "resolved"},
            inserted_at: DateTime.add(@now, -120, :day),
            updated_at: DateTime.add(@now, -120, :day)
          }
        ],
        tool_audits: [
          %ToolAudit{
            id: Ecto.UUID.generate(),
            timeline_entry_id: timeline_entry_id,
            tool_name: "rerun",
            input: %{},
            output: %{},
            success: true,
            inserted_at: DateTime.add(@now, -120, :day),
            updated_at: DateTime.add(@now, -120, :day)
          }
        ],
        action_items: [
          %ActionItem{
            id: Ecto.UUID.generate(),
            incident_id: archived_id,
            title: "Follow up",
            integration: "demo",
            external_id: "item-1",
            inserted_at: DateTime.add(@now, -120, :day),
            updated_at: DateTime.add(@now, -120, :day)
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
            claimed_at: DateTime.add(@now, -120, :day),
            lease_until: DateTime.add(@now, -120, :day),
            error_metadata: %{},
            inserted_at: DateTime.add(@now, -120, :day),
            updated_at: DateTime.add(@now, -120, :day)
          }
        ]
      }

      start_supervised!({FakeRepo, fixtures})

      on_exit(fn ->
        Application.delete_env(:parapet, :archive_now)
        Application.delete_env(:parapet, :archive_run_id)
        Application.delete_env(:parapet, :repo)
        File.rm(archive_path)
        File.rm("#{archive_path}.#{@run_id}.manifest.json")
        File.rm(Path.join(["priv", "parapet", "archive.jsonl"]))
        File.rm(Path.join(["priv", "parapet", "archive.jsonl.#{@run_id}.manifest.json"]))
      end)

      %{archive_path: archive_path, archived_id: archived_id}
    end

    test "defines an Oban worker" do
      changeset = ArchiveWorker.new(%{"days" => 90})
      assert Ecto.Changeset.get_change(changeset, :worker) == "Parapet.Evidence.ArchiveWorker"
    end

    test "archives using explicit job args and returns Summary", %{
      archive_path: archive_path,
      archived_id: archived_id
    } do
      job = %Oban.Job{args: %{"days" => 90, "path" => archive_path}}

      assert {:ok, %Summary{} = summary} = ArchiveWorker.perform(job)
      assert summary.run_id == @run_id
      assert summary.path == archive_path
      assert summary.deleted_count == 1

      snapshot = FakeRepo.snapshot()
      assert snapshot.archived_ids == [archived_id]
      assert snapshot.transactions == 1
      assert File.exists?(archive_path)
      assert snapshot.stream_opts == [[max_rows: 100]]
    end

    test "uses default job args when absent" do
      default_path = Path.join(["priv", "parapet", "archive.jsonl"])
      File.rm(default_path)

      assert {:ok, %Summary{} = summary} = ArchiveWorker.perform(%Oban.Job{args: %{}})

      assert summary.path == default_path
      assert length(FakeRepo.snapshot().archived_ids) == 1
      assert File.exists?(default_path)
    end

    test "returns structured Failure without swallowing it", %{archive_path: archive_path} do
      FakeRepo.set_delete_result({0, nil})

      job = %Oban.Job{args: %{"days" => 90, "path" => archive_path}}

      assert {:error, %Failure{} = failure} = ArchiveWorker.perform(job)
      assert failure.stage == :delete_records
      assert failure.partial_summary.selected_count == 1
      assert failure.partial_summary.archived_count == 1
      assert failure.partial_summary.deleted_count == 0
    end

    defp incident(id, state, inserted_at) do
      %Incident{
        id: id,
        title: state,
        description: state,
        state: state,
        inserted_at: DateTime.truncate(inserted_at, :second),
        updated_at: DateTime.truncate(inserted_at, :second)
      }
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
