defmodule Parapet.Operator.QueuePaginationTest do
  use ExUnit.Case, async: false

  alias Parapet.Operator
  alias Parapet.Spine.Incident

  setup do
    now = ~U[2026-05-10 10:00:00Z]

    Process.put(:mock_incidents, [
      %Incident{id: "inc-4", state: "open", updated_at: now, title: "Newest open"},
      %Incident{id: "inc-3", state: "investigating", updated_at: now, title: "Tie break by id"},
      %Incident{id: "inc-2", state: "open", updated_at: ~U[2026-05-10 09:59:00Z], title: "Older open"},
      %Incident{id: "inc-1", state: "resolved", updated_at: ~U[2026-05-10 09:58:00Z], title: "Resolved"}
    ])

    :ok
  end

  test "returns deterministic keyset metadata for the default active queue" do
    page = Operator.list_incident_queue(page_size: 2)

    assert page.scope == :active
    assert page.direction == :next
    assert page.page_size == 2
    assert page.has_next_page? == true
    assert page.has_previous_page? == false
    assert is_binary(page.next_cursor)
    assert is_nil(page.previous_cursor)
    assert Enum.map(page.items, & &1.id) == ["inc-4", "inc-3"]
  end

  test "falls back to the first page when cursor or direction are invalid" do
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
    assert Enum.map(page.items, & &1.id) == ["inc-4", "inc-3", "inc-2"]
  end

  test "supports previous navigation without changing visible descending order" do
    cursor = Base.url_encode64("2026-05-10T09:59:00Z|inc-2", padding: false)

    Process.put(:mock_incidents, [
      %Incident{id: "inc-5", state: "open", updated_at: ~U[2026-05-10 10:01:00Z], title: "Newest"},
      %Incident{id: "inc-4", state: "open", updated_at: ~U[2026-05-10 10:00:00Z], title: "Current"},
      %Incident{id: "inc-3", state: "investigating", updated_at: ~U[2026-05-10 09:59:59Z], title: "Overflow"}
    ])

    page = Operator.list_incident_queue(page_size: 2, direction: "previous", cursor: cursor)

    assert page.direction == :previous
    assert Enum.map(page.items, & &1.id) == ["inc-4", "inc-5"]
    assert is_binary(page.previous_cursor)
    assert is_binary(page.next_cursor)
  end
end
