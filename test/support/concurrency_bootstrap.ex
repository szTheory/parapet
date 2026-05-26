defmodule Parapet.TestSupport.ConcurrencyBootstrap do
  @moduledoc false

  alias Ecto.Adapters.SQL
  alias Parapet.TestSupport.ConcurrencyRepo

  @tables [
    "parapet_action_claims",
    "parapet_tool_audits",
    "parapet_timeline_entries",
    "parapet_action_items",
    "parapet_system_events",
    "parapet_incidents"
  ]

  def bootstrap! do
    Enum.each(ddl_statements(), &SQL.query!(ConcurrencyRepo, &1, []))
  end

  def reset! do
    SQL.query!(
      ConcurrencyRepo,
      "TRUNCATE #{Enum.join(@tables, ", ")} RESTART IDENTITY CASCADE",
      []
    )
  end

  def table_names, do: @tables

  defp ddl_statements do
    [
      """
      CREATE TABLE IF NOT EXISTS parapet_incidents (
        id uuid PRIMARY KEY,
        title varchar(255) NOT NULL,
        description text,
        state varchar(255) NOT NULL DEFAULT 'open',
        correlation_key varchar(255),
        trace_id varchar(255),
        runbook_data jsonb NOT NULL DEFAULT '{}'::jsonb,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE UNIQUE INDEX IF NOT EXISTS parapet_incidents_correlation_key_open_index
      ON parapet_incidents (correlation_key)
      WHERE state = 'open'
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_incidents_open_updated_at_id_index
      ON parapet_incidents (updated_at, id)
      WHERE state IN ('open', 'investigating')
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_incidents_resolved_updated_at_id_index
      ON parapet_incidents (updated_at, id)
      WHERE state = 'resolved'
      """,
      """
      CREATE TABLE IF NOT EXISTS parapet_action_items (
        id uuid PRIMARY KEY,
        title varchar(255) NOT NULL,
        integration varchar(255) NOT NULL,
        external_id varchar(255) NOT NULL,
        kind varchar(255) NOT NULL DEFAULT 'exact_follow_up',
        state varchar(255) NOT NULL DEFAULT 'open',
        incident_id uuid REFERENCES parapet_incidents(id) ON DELETE SET NULL,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS parapet_timeline_entries (
        id uuid PRIMARY KEY,
        type varchar(255) NOT NULL,
        payload jsonb NOT NULL DEFAULT '{}'::jsonb,
        incident_id uuid NOT NULL REFERENCES parapet_incidents(id) ON DELETE CASCADE,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_timeline_entries_incident_id_index
      ON parapet_timeline_entries (incident_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_timeline_entries_incident_id_inserted_at_index
      ON parapet_timeline_entries (incident_id, inserted_at)
      """,
      """
      CREATE TABLE IF NOT EXISTS parapet_tool_audits (
        id uuid PRIMARY KEY,
        tool_name varchar(255) NOT NULL,
        input jsonb NOT NULL DEFAULT '{}'::jsonb,
        output jsonb NOT NULL DEFAULT '{}'::jsonb,
        success boolean NOT NULL DEFAULT false,
        duration_ms integer,
        timeline_entry_id uuid REFERENCES parapet_timeline_entries(id) ON DELETE CASCADE,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_tool_audits_timeline_entry_id_index
      ON parapet_tool_audits (timeline_entry_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_tool_audits_timeline_entry_id_inserted_at_index
      ON parapet_tool_audits (timeline_entry_id, inserted_at)
      """,
      """
      CREATE TABLE IF NOT EXISTS parapet_system_events (
        id uuid PRIMARY KEY,
        type varchar(255) NOT NULL,
        payload jsonb NOT NULL DEFAULT '{}'::jsonb,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_system_events_inserted_at_index
      ON parapet_system_events (inserted_at)
      """,
      """
      CREATE TABLE IF NOT EXISTS parapet_action_claims (
        id uuid PRIMARY KEY,
        incident_id uuid NOT NULL REFERENCES parapet_incidents(id) ON DELETE CASCADE,
        action_kind varchar(255) NOT NULL,
        action_key varchar(255) NOT NULL,
        status varchar(255) NOT NULL DEFAULT 'claimed',
        idempotency_key varchar(255) NOT NULL,
        attempt_count integer NOT NULL DEFAULT 1,
        claimed_at timestamp(6) without time zone NOT NULL,
        finished_at timestamp(6) without time zone,
        short_circuit_reason varchar(255),
        last_error_kind varchar(255),
        last_error_message text,
        error_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE UNIQUE INDEX IF NOT EXISTS parapet_action_claims_incident_id_action_kind_action_key_index
      ON parapet_action_claims (incident_id, action_kind, action_key)
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_action_claims_status_claimed_at_index
      ON parapet_action_claims (status, claimed_at)
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_action_claims_incident_id_inserted_at_index
      ON parapet_action_claims (incident_id, inserted_at)
      """
    ]
  end
end
