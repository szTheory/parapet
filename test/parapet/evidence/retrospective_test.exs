defmodule Parapet.Evidence.RetrospectiveTest do
  use ExUnit.Case, async: true

  alias Parapet.Evidence.Retrospective
  alias Parapet.Spine.Incident
  alias Parapet.Spine.TimelineEntry

  test "generates markdown retrospective" do
    incident = %Incident{
      id: "inc-1",
      title: "Test Incident",
      description: "Something went wrong",
      state: "resolved",
      inserted_at: ~U[2026-05-11 10:00:00Z],
      updated_at: ~U[2026-05-11 10:05:00Z]
    }

    entries = [
      %TimelineEntry{
        id: "te-1",
        incident_id: incident.id,
        type: "alert",
        payload: %{"text" => "High CPU usage"},
        inserted_at: ~U[2026-05-11 10:00:05Z]
      },
      %TimelineEntry{
        id: "te-2",
        incident_id: incident.id,
        type: "acknowledge",
        payload: %{},
        inserted_at: ~U[2026-05-11 10:01:00Z]
      },
      %TimelineEntry{
        id: "te-3",
        incident_id: incident.id,
        type: "status_change",
        payload: %{"new_state" => "resolved"},
        inserted_at: ~U[2026-05-11 10:05:00Z]
      }
    ]

    markdown = Retrospective.generate_markdown(incident, entries)

    assert markdown =~ "Incident Retrospective: Test Incident"
    assert markdown =~ "**State:** Resolved"
    assert markdown =~ "**Time to Acknowledge:** 1m 0s"
    assert markdown =~ "**Time to Resolve:** 5m 0s"
    assert markdown =~ "Something went wrong"
    assert markdown =~ "High CPU usage"
    assert markdown =~ "State changed to resolved"
    assert markdown =~ "2026-05-11 10:01:00 UTC"
  end
end
