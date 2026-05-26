defmodule Parapet.Operator.QueuePaginationTest do
  use ExUnit.Case, async: false

  alias Parapet.Operator
  alias Parapet.Spine.Incident

  @telemetry_event [:parapet, :operator, :queue, :page]

  defmodule DummyRepo do
    def all(query) do
      send(self(), {:repo_all, query})

      case query.from |> Map.fetch!(:source) |> elem(1) do
        Parapet.Spine.Incident -> Process.get(:mock_incidents, [])
        _ -> []
      end
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)

    now = ~U[2026-05-10 10:00:00Z]

    Process.put(:mock_incidents, [
      %Incident{
        id: "inc-4",
        state: "open",
        updated_at: now,
        title: "Newest open",
        description: "detail-only body",
        trace_id: "trace-123",
        runbook_data: %{
          "triage" => %{
            "integration" => "mailglass",
            "symptom" => "Newest open symptom",
            "fault_plane" => "webhook"
          },
          "correlated_change" => %{"ref" => "deploy-123"}
        }
      },
      %Incident{id: "inc-3", state: "investigating", updated_at: now, title: "Tie break by id"},
      %Incident{
        id: "inc-2",
        state: "open",
        updated_at: ~U[2026-05-10 09:59:00Z],
        title: "Older open"
      },
      %Incident{
        id: "inc-1",
        state: "resolved",
        updated_at: ~U[2026-05-10 09:58:00Z],
        title: "Resolved"
      }
    ])

    on_exit(fn -> Application.delete_env(:parapet, :repo) end)
    :ok
  end

  setup :attach_queue_telemetry_handler

  test "returns deterministic keyset metadata for the default active queue" do
    page = Operator.list_incident_queue(page_size: 2)

    assert page.scope == :active
    assert page.direction == :next
    assert page.page_size == 2
    assert page.has_next_page? == true
    assert page.has_previous_page? == false
    assert is_binary(page.next_cursor)
    assert is_nil(page.previous_cursor)
    assert Enum.map(page.items, & &1.incident_id) == ["inc-4", "inc-3"]

    assert [
             %{
               incident_id: "inc-4",
               title: "Newest open symptom",
               secondary_line: "mailglass • webhook",
               attention_chip: "Correlated change",
               updated_at: ~U[2026-05-10 10:00:00Z],
               updated_at_label: updated_at_label
             }
             | _
           ] = page.items

    assert is_binary(updated_at_label)
    refute Map.has_key?(hd(page.items), :description)
    refute Map.has_key?(hd(page.items), :runbook_data)
    refute Map.has_key?(hd(page.items), :trace_id)
  end

  test "falls back to the first page when cursor or direction are invalid" do
    Process.put(:mock_incidents, [
      %Incident{
        id: "inc-4",
        state: "open",
        updated_at: ~U[2026-05-10 10:00:00Z],
        title: "Newest open"
      },
      %Incident{
        id: "inc-3",
        state: "investigating",
        updated_at: ~U[2026-05-10 10:00:00Z],
        title: "Tie break by id"
      },
      %Incident{
        id: "inc-2",
        state: "open",
        updated_at: ~U[2026-05-10 09:59:00Z],
        title: "Older open"
      }
    ])

    page =
      Operator.list_incident_queue(
        page_size: "nope",
        direction: "sideways",
        cursor: "not-a-cursor"
      )

    assert page.scope == :active
    assert page.direction == :next
    assert page.page_size == 30
    assert page.has_previous_page? == false
    assert Enum.map(page.items, & &1.incident_id) == ["inc-4", "inc-3", "inc-2"]
  end

  test "supports previous navigation without changing visible descending order" do
    cursor = Base.url_encode64("2026-05-10T09:59:00Z|inc-2", padding: false)

    Process.put(:mock_incidents, [
      %Incident{
        id: "inc-3",
        state: "investigating",
        updated_at: ~U[2026-05-10 09:59:59Z],
        title: "Overflow"
      },
      %Incident{
        id: "inc-4",
        state: "open",
        updated_at: ~U[2026-05-10 10:00:00Z],
        title: "Current"
      },
      %Incident{id: "inc-5", state: "open", updated_at: ~U[2026-05-10 10:01:00Z], title: "Newest"}
    ])

    page = Operator.list_incident_queue(page_size: 2, direction: "previous", cursor: cursor)

    assert page.direction == :previous
    assert Enum.map(page.items, & &1.incident_id) == ["inc-5", "inc-4"]
    assert is_binary(page.previous_cursor)
    assert is_binary(page.next_cursor)
  end

  test "emits bounded queue telemetry metadata at the page seam" do
    Operator.list_incident_queue(page_size: 2)

    assert_receive {
      :queue_page_event,
      @telemetry_event,
      measurements,
      metadata
    }

    assert %{duration_ms: duration_ms, duration_native: duration_native} = measurements
    assert is_integer(duration_ms)
    assert duration_ms >= 0
    assert is_integer(duration_native)
    assert duration_native > 0

    assert metadata == %{
             scope: :active,
             direction: :next,
             page_size_bucket: "1-30",
             result_size_bucket: "1-29"
           }

    refute Map.has_key?(metadata, :cursor)
    refute Map.has_key?(metadata, :cursor_value)
    refute Map.has_key?(metadata, :incident_id)
    refute Map.has_key?(metadata, :incident_ids)
  end

  defp attach_queue_telemetry_handler(_context) do
    handler_id = "queue-pagination-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach(
        handler_id,
        @telemetry_event,
        &__MODULE__.handle_queue_page_event/4,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  def handle_queue_page_event(event_name, measurements, metadata, test_pid) do
    send(test_pid, {:queue_page_event, event_name, measurements, metadata})
  end
end
