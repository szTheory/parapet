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

  test "renders recovery_confirmed and recovery_failed entries with human-readable copy" do
    incident = %Incident{
      id: "inc-2",
      title: "Recovery Test Incident",
      description: "Provider outage",
      state: "resolved",
      inserted_at: ~U[2026-05-28 10:00:00Z],
      updated_at: ~U[2026-05-28 10:10:00Z]
    }

    entries = [
      %TimelineEntry{
        id: "te-10",
        incident_id: incident.id,
        type: "recovery_confirmed",
        payload: %{
          "capability" => "retry_async_item",
          "actor" => "ops@example.com",
          "target_refs" => ["job-1"],
          "outcome" => %{"status" => "succeeded", "result" => ":executed"}
        },
        inserted_at: ~U[2026-05-28 10:01:00Z]
      },
      %TimelineEntry{
        id: "te-11",
        incident_id: incident.id,
        type: "recovery_failed",
        payload: %{
          "capability" => "retry_async_item",
          "actor" => "ops@example.com",
          "target_refs" => ["job-2"],
          "outcome" => %{"status" => "failed", "reason" => ":provider_unavailable"}
        },
        inserted_at: ~U[2026-05-28 10:02:00Z]
      }
    ]

    markdown = Retrospective.generate_markdown(incident, entries)

    # Success entry renders human-readable copy naming capability + actor (SC-4)
    assert markdown =~ "retry_async_item confirmed by ops@example.com"

    # Failure entry renders with the distinct "Recovery failed:" prefix
    assert markdown =~ "Recovery failed:"
    assert markdown =~ "retry_async_item"

    # No raw inspect(payload) fallback — the new clauses matched both entries
    refute markdown =~ "%{"

    # Both entries appear inline in the chronological entry list (not a separate section)
    confirmed_pos = :binary.match(markdown, "retry_async_item confirmed by ops@example.com") |> elem(0)
    failed_pos = :binary.match(markdown, "Recovery failed:") |> elem(0)
    assert confirmed_pos < failed_pos, "recovery_confirmed should appear before recovery_failed in chronological order"
  end
end
