defmodule Parapet.ConcurrencyBootstrapTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  alias Ecto.Adapters.SQL
  alias Parapet.Spine.{ActionClaim, ActionItem, Incident, SystemEvent, TimelineEntry, ToolAudit}

  test "bootstraps the canonical Parapet spine tables plus action claims" do
    %{rows: rows} =
      SQL.query!(
        ConcurrencyRepo,
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = ANY($1)
        ORDER BY table_name
        """,
        [ConcurrencyBootstrap.table_names()]
      )

    assert Enum.map(rows, &hd/1) == Enum.sort(ConcurrencyBootstrap.table_names())

    {:ok, incident} =
      %Incident{}
      |> Incident.changeset(%{title: "Boot lane incident"})
      |> ConcurrencyRepo.insert()

    {:ok, entry} =
      %TimelineEntry{}
      |> TimelineEntry.changeset(%{incident_id: incident.id, type: "note", payload: %{"text" => "ok"}})
      |> ConcurrencyRepo.insert()

    assert {:ok, _audit} =
             %ToolAudit{}
             |> ToolAudit.changeset(%{
               timeline_entry_id: entry.id,
               tool_name: "breaker",
               input: %{"step" => "auto_step"},
               success: true
             })
             |> ConcurrencyRepo.insert()

    assert {:ok, _claim} =
             %ActionClaim{}
             |> ActionClaim.changeset(%{
               incident_id: incident.id,
               action_kind: "automation",
               action_key: "auto_step",
               status: "claimed",
               idempotency_key: "auto_exec_#{incident.id}_auto_step",
               attempt_count: 1,
               claimed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
             })
             |> ConcurrencyRepo.insert()

    assert {:ok, _action_item} =
             %ActionItem{}
             |> ActionItem.changeset(%{
               title: "Review duplicate alert",
               integration: "test",
               external_id: "ext-1",
               incident_id: incident.id
             })
             |> ConcurrencyRepo.insert()

    assert {:ok, _event} =
             %SystemEvent{}
             |> SystemEvent.changeset(%{type: "deploy", payload: %{"sha" => "abc"}})
             |> ConcurrencyRepo.insert()
  end
end
