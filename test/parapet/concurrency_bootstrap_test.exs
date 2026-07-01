defmodule Parapet.ConcurrencyBootstrapTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  alias Ecto.Adapters.SQL
  alias Parapet.Spine.{ActionClaim, ActionItem, Incident, SystemEvent, TimelineEntry, ToolAudit}

  # Resolve the schema the bootstrap actually created its tables in under the active
  # prefix leg — `parapet` (or the configured prefix) when set, `public` on the nil leg.
  # The previous hardcoded `public` assertion only passed because of stale public-schema
  # tables left over from before the Phase 52 dual-prefix matrix; on a fresh parapet-leg
  # DB the tables live in the prefixed schema (mirrors ConcurrencyBootstrap.q/1).
  @raw_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")
  @schema Parapet.Spine.Schema.normalize(@raw_prefix) || "public"

  test "bootstraps the canonical Parapet spine tables plus action claims" do
    %{rows: rows} =
      SQL.query!(
        ConcurrencyRepo,
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = $2 AND table_name = ANY($1)
        ORDER BY table_name
        """,
        [ConcurrencyBootstrap.table_names(), @schema]
      )

    assert Enum.map(rows, &hd/1) == Enum.sort(ConcurrencyBootstrap.table_names())

    {:ok, incident} =
      %Incident{}
      |> Incident.changeset(%{title: "Boot lane incident"})
      |> ConcurrencyRepo.insert()

    {:ok, entry} =
      %TimelineEntry{}
      |> TimelineEntry.changeset(%{
        incident_id: incident.id,
        type: "note",
        payload: %{"text" => "ok"}
      })
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

    claimed_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    lease_until = DateTime.add(claimed_at, 5 * 60, :second) |> DateTime.truncate(:microsecond)

    assert {:ok, _claim} =
             %ActionClaim{}
             |> ActionClaim.changeset(%{
               incident_id: incident.id,
               action_kind: "automation",
               action_key: "auto_step",
               status: "claimed",
               idempotency_key: "auto_exec_#{incident.id}_auto_step",
               attempt_count: 1,
               claimed_at: claimed_at,
               lease_until: lease_until
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
