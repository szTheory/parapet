defmodule Parapet.Repo.Migrations.MoveSpineToParapetSchemaTest do
  @moduledoc """
  Track B round-trip integration test for the committed `MoveParapetSpineToSchema` migration
  (Plan 02 committed fixture at `priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs`).

  Decision references (trace each assertion back to a locked decision):
  - D-13: `Code.require_file` loads the SAME committed fixture Plan 02 produced — the golden test
    and this test reference one file so they cannot drift (Pitfall 5).
  - D-14: Dedicated throwaway DB `parapet_schema_move_roundtrip_test` via `storage_up`/`storage_down`
    — NOT the shared `parapet_concurrency_test` (Pitfall 4). A whole-schema move is too destructive
    for shared state; a mid-test abort cannot poison other `:unboxed` modules.
  - D-15: Fixture spine is hand-written BARE `public` DDL (not routed through `ConcurrencyBootstrap.q/1`)
    so the test runs byte-identically on both CI legs (`PARAPET_SCHEMA_PREFIX=parapet` and `=''`)
    (Pitfall 1). The migration itself always moves from `public`, matching the fixture.
  - D-16: Four assertion dimensions after UP:
    (a) table membership via `pg_class` JOIN `pg_namespace`;
    (b) FK cascade BEHAVIOR (insert parent+child, delete parent, assert child cascaded);
    (c) partial-index byte-identical name + `pg_get_expr(indpred, indrelid)` predicate;
    (d) after DOWN: both tables back in `public` AND `parapet` schema exists but is empty of spine tables
        (proves the deliberate no-DROP-SCHEMA from D-08).
  - D-10: Abort leg — drop a fixture table before `up`, assert `RAISE EXCEPTION` fires, nothing moved.

  Satisfies UPG-04 (round-trip proof) and provides the authoritative DB-level gate for UPG-03 (D-10 abort).
  """

  use ExUnit.Case, async: false

  alias Parapet.TestSupport.ConcurrencyRepo

  # Committed fixture migration (Plan 02). `Code.require_file` so `Ecto.Migrator` can introspect
  # the module. The path is relative to __DIR__ (test/parapet/repo/migrations/).
  # D-13: Do NOT generate the migration live in this test — that couples the DB test to
  # file-writing + pre-flight and creates fixture-drift risk.
  Code.require_file(
    "../../../../priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs",
    __DIR__
  )

  @migration_version 20_260_701_000_000
  @migration_module Parapet.Repo.Migrations.MoveParapetSpineToSchema

  # Dedicated throwaway DB (D-14, Pitfall 4). NOT parapet_concurrency_test.
  @throwaway_db "parapet_schema_move_roundtrip_test"

  # Private MigrationTestRepo on a plain ConnectionPool (not Sandbox).
  # Ecto.Migrator needs ≥2 simultaneous connections — one to lock `schema_migrations`
  # and one to execute DDL — which the ownership-based Sandbox pool cannot provide.
  defmodule MigrationTestRepo do
    @moduledoc false
    use Ecto.Repo,
      otp_app: :parapet,
      adapter: Ecto.Adapters.Postgres
  end

  setup_all do
    # Build config from the concurrency repo base, override database (D-14) and pool.
    cfg =
      ConcurrencyRepo.database_config()
      |> Keyword.put(:database, @throwaway_db)
      |> Keyword.put(:pool, DBConnection.ConnectionPool)
      |> Keyword.put(:pool_size, 5)
      |> Keyword.delete(:ownership_timeout)

    # Create the dedicated throwaway DB (D-14). storage_up/1 is idempotent — `:already_up` is fine.
    _ = Ecto.Adapters.Postgres.storage_up(cfg)

    # Start the migration repo against the throwaway DB.
    {:ok, _pid} = MigrationTestRepo.start_link(cfg)

    # Ensure schema_migrations exists in the throwaway DB.
    MigrationTestRepo.query!(
      "CREATE TABLE IF NOT EXISTS schema_migrations " <>
        "(version bigint PRIMARY KEY, inserted_at timestamp(0) without time zone)",
      []
    )

    # Bare Postgrex connection for out-of-transaction DDL/DML assertions (D-13 idiom).
    postgrex_cfg = Keyword.take(cfg, [:hostname, :port, :database, :username, :password])
    {:ok, conn} = Postgrex.start_link(postgrex_cfg)

    # Build the isolated fixture spine in `public` (D-15, Pitfall 1 — bare DDL, NOT ConcurrencyBootstrap.q/1).
    create_public_fixture_spine!(conn)

    on_exit(fn ->
      # Single-call teardown: stop the bare conn, then nuke the throwaway DB (D-14).
      GenServer.stop(conn)
      Ecto.Adapters.Postgres.storage_down(cfg)
    end)

    {:ok, conn: conn, cfg: cfg}
  end

  # ---------------------------------------------------------------------------
  # Fixture helpers (D-15: bare public DDL, byte-identical on both CI legs)
  # ---------------------------------------------------------------------------

  # Create all six spine tables in `public` matching the committed migration's abort guard.
  # The migration's DO-block FOREACH checks ALL SIX tables by name; the fixture must create
  # all six or the abort guard raises before any SET SCHEMA (breaking the round-trip test).
  # D-15: Bare `public` DDL — NOT routed through `ConcurrencyBootstrap.q/1`. Byte-identical
  # on both CI legs. All PKs are UUID (no sequences — no orphaned-sequence footgun).
  # The two-table FK/partial-index pair (parapet_incidents + parapet_action_claims) is the
  # load-bearing part for D-16b/D-16c; the other four are minimal stubs satisfying the guard.
  defp create_public_fixture_spine!(conn) do
    # Drop everything in LIFO dependency order (idempotent setup).
    Postgrex.query!(
      conn,
      "DROP INDEX IF EXISTS public.parapet_action_claims_lease_until_claimed_index",
      []
    )

    Postgrex.query!(conn, "DROP TABLE IF EXISTS public.parapet_action_claims CASCADE", [])
    Postgrex.query!(conn, "DROP TABLE IF EXISTS public.parapet_tool_audits CASCADE", [])
    Postgrex.query!(conn, "DROP TABLE IF EXISTS public.parapet_timeline_entries CASCADE", [])
    Postgrex.query!(conn, "DROP TABLE IF EXISTS public.parapet_action_items CASCADE", [])
    Postgrex.query!(conn, "DROP TABLE IF EXISTS public.parapet_system_events CASCADE", [])
    Postgrex.query!(conn, "DROP TABLE IF EXISTS public.parapet_incidents CASCADE", [])

    # 1. Parent table: parapet_incidents (binary_id PK).
    Postgrex.query!(
      conn,
      """
      CREATE TABLE public.parapet_incidents (
        id uuid NOT NULL PRIMARY KEY,
        title text NOT NULL,
        state text NOT NULL DEFAULT 'open',
        inserted_at timestamp(6) WITHOUT TIME ZONE NOT NULL,
        updated_at timestamp(6) WITHOUT TIME ZONE NOT NULL
      )
      """,
      []
    )

    # 2. parapet_action_items (minimal stub — satisfies abort guard; no intra-spine FK in lib).
    Postgrex.query!(
      conn,
      """
      CREATE TABLE public.parapet_action_items (
        id uuid NOT NULL PRIMARY KEY,
        title text NOT NULL,
        inserted_at timestamp(6) WITHOUT TIME ZONE NOT NULL,
        updated_at timestamp(6) WITHOUT TIME ZONE NOT NULL
      )
      """,
      []
    )

    # 3. parapet_timeline_entries (FK → parapet_incidents ON DELETE CASCADE).
    Postgrex.query!(
      conn,
      """
      CREATE TABLE public.parapet_timeline_entries (
        id uuid NOT NULL PRIMARY KEY,
        type text NOT NULL,
        incident_id uuid NOT NULL
          REFERENCES public.parapet_incidents(id) ON DELETE CASCADE,
        inserted_at timestamp(6) WITHOUT TIME ZONE NOT NULL,
        updated_at timestamp(6) WITHOUT TIME ZONE NOT NULL
      )
      """,
      []
    )

    # 4. parapet_tool_audits (FK → parapet_timeline_entries ON DELETE CASCADE).
    Postgrex.query!(
      conn,
      """
      CREATE TABLE public.parapet_tool_audits (
        id uuid NOT NULL PRIMARY KEY,
        tool_name text NOT NULL,
        timeline_entry_id uuid
          REFERENCES public.parapet_timeline_entries(id) ON DELETE CASCADE,
        inserted_at timestamp(6) WITHOUT TIME ZONE NOT NULL,
        updated_at timestamp(6) WITHOUT TIME ZONE NOT NULL
      )
      """,
      []
    )

    # 5. parapet_system_events (standalone, no FK).
    Postgrex.query!(
      conn,
      """
      CREATE TABLE public.parapet_system_events (
        id uuid NOT NULL PRIMARY KEY,
        type text NOT NULL,
        inserted_at timestamp(6) WITHOUT TIME ZONE NOT NULL,
        updated_at timestamp(6) WITHOUT TIME ZONE NOT NULL
      )
      """,
      []
    )

    # 6. parapet_action_claims — load-bearing for D-16b (FK cascade behavior) and D-16c (partial index).
    Postgrex.query!(
      conn,
      """
      CREATE TABLE public.parapet_action_claims (
        id uuid NOT NULL PRIMARY KEY,
        incident_id uuid NOT NULL
          REFERENCES public.parapet_incidents(id) ON DELETE CASCADE,
        status text NOT NULL DEFAULT 'pending',
        lease_until timestamp(6) WITHOUT TIME ZONE,
        inserted_at timestamp(6) WITHOUT TIME ZONE NOT NULL,
        updated_at timestamp(6) WITHOUT TIME ZONE NOT NULL
      )
      """,
      []
    )

    # Partial index on lease_until WHERE status = 'claimed' (D-16c).
    Postgrex.query!(
      conn,
      """
      CREATE INDEX parapet_action_claims_lease_until_claimed_index
        ON public.parapet_action_claims (lease_until)
        WHERE (status = 'claimed')
      """,
      []
    )
  end

  # Re-create the fixture spine in `public` for a fresh abort-leg run.
  # Called in the abort test to restore the spine after the pre-drop + abort attempt.
  defp restore_public_fixture_spine!(conn) do
    create_public_fixture_spine!(conn)
  end

  # ---------------------------------------------------------------------------
  @all_six_tables ~w(
    parapet_action_items
    parapet_incidents
    parapet_timeline_entries
    parapet_tool_audits
    parapet_system_events
    parapet_action_claims
  )

  # ---------------------------------------------------------------------------
  # @tag :unboxed Test 1 — round-trip up/down (UPG-04, D-13/14/15/16)
  # ---------------------------------------------------------------------------

  @tag :unboxed
  test "round-trip: public → up → parapet (FK cascade + partial index) → down → public (schema empty, not dropped)",
       %{conn: conn} do
    # Ensure a clean migration-version state before running.
    Postgrex.query!(conn, "DELETE FROM schema_migrations WHERE version = $1", [@migration_version])

    # --- UP ---

    result = Ecto.Migrator.up(MigrationTestRepo, @migration_version, @migration_module, log: false)

    assert result in [:ok, :already_up],
           "Expected Ecto.Migrator.up to return :ok or :already_up, got: #{inspect(result)}"

    # (D-16a) Membership: all six fixture tables must now resolve under `parapet`, not `public`.
    assert_tables_in_schema(conn, "parapet", @all_six_tables)
    assert_tables_not_in_schema(conn, "public", @all_six_tables)

    # (D-16b) FK cascade BEHAVIOR: insert parent incident + child claim in `parapet`,
    # delete the parent, assert the child was CASCADE-deleted.
    incident_id = Ecto.UUID.generate()
    claim_id = Ecto.UUID.generate()
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:microsecond)

    Postgrex.query!(
      conn,
      """
      INSERT INTO parapet.parapet_incidents (id, title, state, inserted_at, updated_at)
      VALUES ($1, 'rt-parent', 'open', $2, $2)
      """,
      [Ecto.UUID.dump!(incident_id), now]
    )

    Postgrex.query!(
      conn,
      """
      INSERT INTO parapet.parapet_action_claims (id, incident_id, status, inserted_at, updated_at)
      VALUES ($1, $2, 'pending', $3, $3)
      """,
      [Ecto.UUID.dump!(claim_id), Ecto.UUID.dump!(incident_id), now]
    )

    # Verify child exists before the cascade.
    %{rows: pre_rows} =
      Postgrex.query!(
        conn,
        "SELECT id FROM parapet.parapet_action_claims WHERE id = $1",
        [Ecto.UUID.dump!(claim_id)]
      )

    assert length(pre_rows) == 1, "Expected child claim to exist before cascade"

    # Delete the parent — cascade should remove the child.
    Postgrex.query!(
      conn,
      "DELETE FROM parapet.parapet_incidents WHERE id = $1",
      [Ecto.UUID.dump!(incident_id)]
    )

    %{rows: post_rows} =
      Postgrex.query!(
        conn,
        "SELECT id FROM parapet.parapet_action_claims WHERE id = $1",
        [Ecto.UUID.dump!(claim_id)]
      )

    assert post_rows == [],
           "Expected child claim to be CASCADE-deleted when parent incident was deleted (D-16b)"

    # (D-16c) Partial index: assert the index exists under `parapet` with its byte-identical name
    # and that pg_get_expr(indpred, indrelid) renders the `status = 'claimed'` predicate.
    %{rows: index_rows} =
      Postgrex.query!(
        conn,
        """
        SELECT i.relname, pg_get_expr(ix.indpred, ix.indrelid)
        FROM pg_index ix
        JOIN pg_class i ON i.oid = ix.indexrelid
        JOIN pg_class t ON t.oid = ix.indrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = 'parapet'
          AND t.relname = 'parapet_action_claims'
          AND i.relname = 'parapet_action_claims_lease_until_claimed_index'
        """,
        []
      )

    assert length(index_rows) == 1,
           "Expected partial index `parapet_action_claims_lease_until_claimed_index` under `parapet` (D-16c)"

    [[index_name, predicate]] = index_rows

    assert index_name == "parapet_action_claims_lease_until_claimed_index",
           "Expected byte-identical index name, got: #{index_name}"

    assert predicate =~ "status",
           "Expected partial index predicate to contain 'status', got: #{inspect(predicate)}"

    assert predicate =~ "claimed",
           "Expected partial index predicate to contain 'claimed', got: #{inspect(predicate)}"

    # --- DOWN ---

    down_result =
      Ecto.Migrator.down(MigrationTestRepo, @migration_version, @migration_module, log: false)

    assert down_result in [:ok, :already_down],
           "Expected Ecto.Migrator.down to return :ok or :already_down, got: #{inspect(down_result)}"

    # (D-16d) After down: all six tables back in `public`.
    assert_tables_in_schema(conn, "public", @all_six_tables)
    assert_tables_not_in_schema(conn, "parapet", @all_six_tables)

    # (D-16d) The `parapet` schema STILL EXISTS (no DROP SCHEMA — D-08 deliberate fail-closed).
    %{rows: [[schema_exists]]} =
      Postgrex.query!(
        conn,
        "SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'parapet')",
        []
      )

    assert schema_exists,
           "Expected `parapet` schema to still exist after down (deliberate no-DROP-SCHEMA, D-08/D-16d)"

    # (D-16d) The `parapet` schema is EMPTY of the two fixture tables (spine tables moved back).
    assert_tables_not_in_schema(conn, "parapet", ["parapet_incidents", "parapet_action_claims"])
  end

  # ---------------------------------------------------------------------------
  # @tag :unboxed Test 2 — abort leg (UPG-03, D-10)
  # ---------------------------------------------------------------------------

  @tag :unboxed
  test "abort leg: missing fixture table makes the migration RAISE and nothing moves (UPG-03, D-10)",
       %{conn: conn} do
    # Clean up any leftover migration version so we get a fresh run.
    Postgrex.query!(conn, "DELETE FROM schema_migrations WHERE version = $1", [@migration_version])

    # Ensure all six tables are in `public` (re-build from scratch to handle the case
    # where Test 1 ran first and moved tables to `parapet` then back, or left partial state).
    restore_public_fixture_spine!(conn)

    # Drop ONE fixture table to trigger the D-10 abort guard.
    # The migration's DO-block FOREACH checks all six; dropping `parapet_action_claims`
    # (the 6th in the array) causes: to_regclass('public.parapet_action_claims') IS NULL → RAISE EXCEPTION.
    # Using CASCADE to drop the partial index too.
    Postgrex.query!(
      conn,
      "DROP TABLE IF EXISTS public.parapet_action_claims CASCADE",
      []
    )

    # The surviving five tables must be in `public` before the abort attempt.
    surviving_tables = @all_six_tables -- ["parapet_action_claims"]
    assert_tables_in_schema(conn, "public", surviving_tables)

    # Invoke the migration — the DO-block abort guard MUST raise a Postgrex.Error
    # (Ecto wraps PL/pgSQL RAISE EXCEPTION as a Postgrex.Error, not a RuntimeError).
    # D-10: nothing moves because the RAISE fires inside the transaction before any SET SCHEMA.
    assert_raise Postgrex.Error, fn ->
      Ecto.Migrator.up(MigrationTestRepo, @migration_version, @migration_module, log: false)
    end

    # After the abort, the surviving fixture tables must STILL be in `public` (nothing moved).
    # The migration is transactional (no @disable_ddl_transaction) so the RAISE rolled back
    # everything including any partial SET SCHEMA.
    assert_tables_in_schema(conn, "public", surviving_tables)
    assert_tables_not_in_schema(conn, "parapet", surviving_tables)

    # The migration version must NOT be recorded (the txn rolled back, D-10).
    %{rows: [[version_recorded]]} =
      Postgrex.query!(
        conn,
        "SELECT COUNT(*) FROM schema_migrations WHERE version = $1",
        [@migration_version]
      )

    assert version_recorded == 0,
           "Expected migration version NOT to be recorded after abort (txn rolled back, D-10)"

    # Clean up: restore the full fixture spine for subsequent test runs.
    restore_public_fixture_spine!(conn)
  end

  # ---------------------------------------------------------------------------
  # Private assertion helpers
  # ---------------------------------------------------------------------------

  # Assert each table in `table_names` has `nspname = schema_name` in pg_namespace.
  defp assert_tables_in_schema(conn, schema_name, table_names) do
    for table <- table_names do
      %{rows: [[count]]} =
        Postgrex.query!(
          conn,
          """
          SELECT COUNT(*) FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname = $1 AND c.relname = $2 AND c.relkind = 'r'
          """,
          [schema_name, table]
        )

      assert count == 1,
             "Expected table `#{table}` to be in schema `#{schema_name}` but it was not (D-16a)"
    end
  end

  # Assert each table in `table_names` does NOT have `nspname = schema_name`.
  defp assert_tables_not_in_schema(conn, schema_name, table_names) do
    for table <- table_names do
      %{rows: [[count]]} =
        Postgrex.query!(
          conn,
          """
          SELECT COUNT(*) FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname = $1 AND c.relname = $2 AND c.relkind = 'r'
          """,
          [schema_name, table]
        )

      assert count == 0,
             "Expected table `#{table}` NOT to be in schema `#{schema_name}` but it was (D-16a)"
    end
  end
end
