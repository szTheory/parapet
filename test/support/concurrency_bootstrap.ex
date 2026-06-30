defmodule Parapet.TestSupport.ConcurrencyBootstrap do
  @moduledoc false

  alias Ecto.Adapters.SQL
  alias Parapet.TestSupport.ConcurrencyRepo

  # Resolve the prefix at compile time — same normalization the macro uses (D-04).
  # Reading compile_env here (not a literal) keeps the public/unprefixed leg unchanged
  # for Phase 52 (Anti-Pattern: "Hardcoding parapet").
  @raw_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")
  @prefix (case @raw_prefix do
             p when p in [nil, "", "public"] -> nil
             other when is_binary(other) -> other
             other when is_atom(other) -> Atom.to_string(other)
           end)

  @tables [
    "parapet_action_claims",
    "parapet_tool_audits",
    "parapet_timeline_entries",
    "parapet_action_items",
    "parapet_system_events",
    "parapet_incidents"
  ]

  def bootstrap! do
    if @prefix do
      SQL.query!(ConcurrencyRepo, ~s(CREATE SCHEMA IF NOT EXISTS "#{@prefix}"), [])
    end

    Enum.each(ddl_statements(), &SQL.query!(ConcurrencyRepo, &1, []))
  end

  def reset! do
    qualified_tables = Enum.map(@tables, &q/1)

    SQL.query!(
      ConcurrencyRepo,
      "TRUNCATE #{Enum.join(qualified_tables, ", ")} RESTART IDENTITY CASCADE",
      []
    )
  end

  def table_names, do: @tables

  # Qualifies a bare table name with the resolved prefix.
  # When @prefix is non-nil: returns ~s("prefix"."table")
  # When @prefix is nil: returns ~s("table") (public leg — byte-identical to legacy)
  defp q(table) do
    if @prefix do
      ~s("#{@prefix}"."#{table}")
    else
      ~s("#{table}")
    end
  end

  defp ddl_statements do
    # Every CREATE TABLE target, every REFERENCES target, and every CREATE INDEX ON target
    # flows through q/1 so that the correct schema is used under the compiled @prefix.
    # Index NAMES are left bare — qualifying an index name is invalid Postgres (Pitfall 1).
    # Under @prefix nil every q/1 call returns a bare "table" identifier, preserving the
    # public/legacy leg byte-for-byte (Phase 52 unprefixed axis).
    [
      """
      CREATE TABLE IF NOT EXISTS #{q("parapet_incidents")} (
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
      ON #{q("parapet_incidents")} (correlation_key)
      WHERE state = 'open'
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_incidents_open_updated_at_id_index
      ON #{q("parapet_incidents")} (updated_at, id)
      WHERE state IN ('open', 'investigating')
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_incidents_resolved_updated_at_id_index
      ON #{q("parapet_incidents")} (updated_at, id)
      WHERE state = 'resolved'
      """,
      """
      CREATE TABLE IF NOT EXISTS #{q("parapet_action_items")} (
        id uuid PRIMARY KEY,
        title varchar(255) NOT NULL,
        integration varchar(255) NOT NULL,
        external_id varchar(255) NOT NULL,
        kind varchar(255) NOT NULL DEFAULT 'exact_follow_up',
        state varchar(255) NOT NULL DEFAULT 'open',
        incident_id uuid REFERENCES #{q("parapet_incidents")}(id) ON DELETE SET NULL,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE TABLE IF NOT EXISTS #{q("parapet_timeline_entries")} (
        id uuid PRIMARY KEY,
        type varchar(255) NOT NULL,
        payload jsonb NOT NULL DEFAULT '{}'::jsonb,
        incident_id uuid NOT NULL REFERENCES #{q("parapet_incidents")}(id) ON DELETE CASCADE,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_timeline_entries_incident_id_index
      ON #{q("parapet_timeline_entries")} (incident_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_timeline_entries_incident_id_inserted_at_index
      ON #{q("parapet_timeline_entries")} (incident_id, inserted_at)
      """,
      """
      CREATE TABLE IF NOT EXISTS #{q("parapet_tool_audits")} (
        id uuid PRIMARY KEY,
        tool_name varchar(255) NOT NULL,
        input jsonb NOT NULL DEFAULT '{}'::jsonb,
        output jsonb NOT NULL DEFAULT '{}'::jsonb,
        success boolean NOT NULL DEFAULT false,
        duration_ms integer,
        timeline_entry_id uuid REFERENCES #{q("parapet_timeline_entries")}(id) ON DELETE CASCADE,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_tool_audits_timeline_entry_id_index
      ON #{q("parapet_tool_audits")} (timeline_entry_id)
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_tool_audits_timeline_entry_id_inserted_at_index
      ON #{q("parapet_tool_audits")} (timeline_entry_id, inserted_at)
      """,
      """
      CREATE TABLE IF NOT EXISTS #{q("parapet_system_events")} (
        id uuid PRIMARY KEY,
        type varchar(255) NOT NULL,
        payload jsonb NOT NULL DEFAULT '{}'::jsonb,
        inserted_at timestamp(6) without time zone NOT NULL,
        updated_at timestamp(6) without time zone NOT NULL
      )
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_system_events_inserted_at_index
      ON #{q("parapet_system_events")} (inserted_at)
      """,
      """
      CREATE TABLE IF NOT EXISTS #{q("parapet_action_claims")} (
        id uuid PRIMARY KEY,
        incident_id uuid NOT NULL REFERENCES #{q("parapet_incidents")}(id) ON DELETE CASCADE,
        action_kind varchar(255) NOT NULL,
        action_key varchar(255) NOT NULL,
        status varchar(255) NOT NULL DEFAULT 'claimed',
        idempotency_key varchar(255) NOT NULL,
        attempt_count integer NOT NULL DEFAULT 1,
        claimed_at timestamp(6) without time zone NOT NULL,
        lease_until timestamp(6) without time zone NOT NULL,
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
      ON #{q("parapet_action_claims")} (incident_id, action_kind, action_key)
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_action_claims_status_claimed_at_index
      ON #{q("parapet_action_claims")} (status, claimed_at)
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_action_claims_lease_until_claimed_index
      ON #{q("parapet_action_claims")} (lease_until)
      WHERE status = 'claimed'
      """,
      """
      CREATE INDEX IF NOT EXISTS parapet_action_claims_incident_id_inserted_at_index
      ON #{q("parapet_action_claims")} (incident_id, inserted_at)
      """
    ]
  end
end
