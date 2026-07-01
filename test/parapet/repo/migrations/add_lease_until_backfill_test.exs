defmodule Parapet.Repo.Migrations.AddLeaseUntilBackfillTest do
  @moduledoc """
  Integration test proving the AddLeaseUntilToParapetActionClaims migration
  backfills `lease_until = claimed_at + INTERVAL '5 minutes'` on pre-existing rows.

  Proves FND-01 Success Criterion #1: running the migration against a DB that
  already has parapet_action_claims rows backfills lease_until = claimed_at + 5 min.

  Uses Ecto.Migrator against a plain (non-sandbox) connection pool so DDL and
  multi-connection locking work correctly — the same DB as ConcurrencyRepo
  (parapet_concurrency_test) but via a dedicated pool that bypasses the sandbox.
  """

  use ExUnit.Case, async: false

  alias Parapet.TestSupport.ConcurrencyRepo

  # Schema-prefix-aware table qualification — mirrors ConcurrencyBootstrap.q/1 so this
  # integration test targets the SAME schema the bootstrap and the migration use under
  # the active prefix leg. The bare Postgrex connection below sets no search_path, so
  # unqualified names resolve to `public`; under the `parapet` leg the bootstrap creates
  # tables in the `parapet` schema, so unqualified DDL/DML would miss them entirely
  # (Phase 52 dual-prefix matrix). Under the `public`/nil leg every qualifier is bare,
  # preserving the legacy behavior byte-for-byte.
  @raw_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")
  @prefix Parapet.Spine.Schema.normalize(@raw_prefix)
  @claims_table if @prefix,
                  do: ~s("#{@prefix}"."parapet_action_claims"),
                  else: "parapet_action_claims"
  @incidents_table if @prefix,
                     do: ~s("#{@prefix}"."parapet_incidents"),
                     else: "parapet_incidents"
  # DROP INDEX qualifies the index by its schema; CREATE INDEX must leave the index
  # name bare (it inherits the target table's schema).
  @lease_index if @prefix,
                 do: ~s("#{@prefix}"."parapet_action_claims_lease_until_claimed_index"),
                 else: "parapet_action_claims_lease_until_claimed_index"

  # Backfill migration under test.
  @migration_version 20_260_528_010_000
  @migration_module Parapet.Repo.Migrations.AddLeaseUntilToParapetActionClaims

  # Migration files are not compiled into test paths by default (they live in
  # priv/repo/migrations). Load the module explicitly so Ecto.Migrator can
  # introspect it via Code.ensure_loaded?/1 before running.
  Code.require_file(
    "../../../../priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs",
    __DIR__
  )

  # A minimal Ecto Repo backed by a plain DBConnection.ConnectionPool (NOT a
  # Sandbox pool). Ecto.Migrator needs at least two simultaneous connections —
  # one to lock schema_migrations and one to execute the migration DDL — which
  # the ownership-based Sandbox pool cannot provide across different processes.
  defmodule MigrationTestRepo do
    @moduledoc false
    use Ecto.Repo,
      otp_app: :parapet,
      adapter: Ecto.Adapters.Postgres
  end

  setup_all do
    db_config = ConcurrencyRepo.database_config()

    # Override the pool to a plain connection pool so Ecto.Migrator works.
    migration_config =
      db_config
      |> Keyword.put(:pool, DBConnection.ConnectionPool)
      |> Keyword.put(:pool_size, 5)
      |> Keyword.delete(:ownership_timeout)

    # Start the migration repo; it connects to the same parapet_concurrency_test DB.
    {:ok, _pid} = MigrationTestRepo.start_link(migration_config)

    # Ensure schema_migrations exists in the concurrency test DB.
    MigrationTestRepo.query!(
      "CREATE TABLE IF NOT EXISTS schema_migrations " <>
        "(version bigint PRIMARY KEY, inserted_at timestamp(0) without time zone)",
      []
    )

    # Also start a bare Postgrex connection for pre/post-migration DDL that must
    # run OUTSIDE any Ecto.Migrator transaction (e.g., DROP COLUMN, INSERT without
    # lease_until). This avoids "cannot run DDL inside a transaction" issues.
    {:ok, conn} =
      Postgrex.start_link(
        hostname: db_config[:hostname],
        port: db_config[:port],
        database: db_config[:database],
        username: db_config[:username],
        password: db_config[:password]
      )

    on_exit(fn ->
      # Tear down: restore the DB to the canonical post-bootstrap state so
      # subsequent test modules see the same schema ConcurrencyBootstrap
      # declared at suite start (see test/support/concurrency_bootstrap.ex).
      #
      # ConcurrencyBootstrap.bootstrap!/0 only runs once (at test_helper.exs
      # startup), so we can't just drop the column and rely on a re-bootstrap.
      # Instead, mirror the canonical DDL exactly: NOT NULL column + partial
      # index. This makes teardown self-contained and idempotent regardless
      # of which step of the test left the column in.

      # WR-06: remove only this migration's row, not the whole schema_migrations
      # table. The row-level DELETE is idempotent and sufficient for cleanup;
      # DROP TABLE would be needlessly broad and would couple this teardown
      # to the assumption that no other test in the suite uses schema_migrations.
      Postgrex.query!(conn, "DELETE FROM schema_migrations WHERE version = $1", [
        @migration_version
      ])

      # WR-05: restore lease_until to match the canonical bootstrap DDL
      # (NOT NULL, with the partial index). The migration under test may have
      # left the column either dropped (if the test failed before step 4), or
      # present-and-NOT-NULL (if the migration ran fully), or present-and-NULLABLE
      # (if the migration's intermediate state was observed). Handle all three:
      #
      # 1. ADD COLUMN IF NOT EXISTS — covers the dropped case.
      # 2. Backfill any NULL rows — required before we can set NOT NULL.
      # 3. SET NOT NULL — restore canonical bootstrap declaration; idempotent
      #    when the column is already NOT NULL.
      Postgrex.query!(
        conn,
        "ALTER TABLE #{@claims_table} ADD COLUMN IF NOT EXISTS lease_until timestamp(6) without time zone",
        []
      )

      Postgrex.query!(
        conn,
        "UPDATE #{@claims_table} SET lease_until = claimed_at + INTERVAL '5 minutes' WHERE lease_until IS NULL",
        []
      )

      Postgrex.query!(
        conn,
        "ALTER TABLE #{@claims_table} ALTER COLUMN lease_until SET NOT NULL",
        []
      )

      # Re-create the partial index if the migration dropped it via rollback.
      Postgrex.query!(
        conn,
        "CREATE INDEX IF NOT EXISTS parapet_action_claims_lease_until_claimed_index ON #{@claims_table} (lease_until) WHERE status = 'claimed'",
        []
      )

      # Remove test rows so successive runs are deterministic.
      Postgrex.query!(
        conn,
        "DELETE FROM #{@claims_table} WHERE action_key = 'migration-backfill-test'",
        []
      )

      Postgrex.query!(
        conn,
        "DELETE FROM #{@incidents_table} WHERE title = 'migration-backfill-verify'",
        []
      )

      GenServer.stop(conn)
    end)

    {:ok, conn: conn}
  end

  @tag :unboxed
  test "backfills lease_until = claimed_at + 5 minutes on pre-existing rows via Ecto.Migrator",
       %{conn: conn} do
    # -----------------------------------------------------------------------
    # Step 1: Ensure a clean pre-migration state.
    # Remove any migration version record left by a prior test run.
    # -----------------------------------------------------------------------
    Postgrex.query!(conn, "DELETE FROM schema_migrations WHERE version = $1", [
      @migration_version
    ])

    # -----------------------------------------------------------------------
    # Step 2: Drop lease_until column + index to simulate the DB state BEFORE
    # the migration ran. This is what the concurrency_test DB looked like before
    # Task 1 of this plan was implemented.
    # -----------------------------------------------------------------------
    Postgrex.query!(
      conn,
      "DROP INDEX IF EXISTS #{@lease_index}",
      []
    )

    Postgrex.query!(
      conn,
      "ALTER TABLE #{@claims_table} DROP COLUMN IF EXISTS lease_until",
      []
    )

    # -----------------------------------------------------------------------
    # Step 3: Insert a parent incident + a pre-existing action_claim row.
    # The claim is inserted WITHOUT lease_until because the column doesn't exist
    # yet — this is the "pre-existing row" the backfill must fix.
    # -----------------------------------------------------------------------
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    incident_id = Ecto.UUID.generate()

    Postgrex.query!(
      conn,
      "INSERT INTO #{@incidents_table} (id, title, state, runbook_data, inserted_at, updated_at) " <>
        "VALUES ($1, 'migration-backfill-verify', 'open', '{}', $2, $2)",
      [Ecto.UUID.dump!(incident_id), now]
    )

    claim_id = Ecto.UUID.generate()
    # claimed_at is 10 minutes in the past — a realistic crashed-node scenario.
    claimed_at = DateTime.add(now, -10 * 60, :second) |> DateTime.truncate(:microsecond)

    Postgrex.query!(
      conn,
      "INSERT INTO #{@claims_table} " <>
        "(id, incident_id, action_kind, action_key, status, idempotency_key, " <>
        "attempt_count, claimed_at, error_metadata, inserted_at, updated_at) " <>
        "VALUES ($1, $2, 'operator', 'migration-backfill-test', 'claimed', " <>
        "'verify-key', 1, $3, '{}', $3, $3)",
      [Ecto.UUID.dump!(claim_id), Ecto.UUID.dump!(incident_id), claimed_at]
    )

    # -----------------------------------------------------------------------
    # Step 4: Run the migration UP via Ecto.Migrator.
    # MigrationTestRepo uses DBConnection.ConnectionPool (non-sandbox), so
    # Ecto.Migrator can acquire multiple simultaneous connections for its
    # internal schema_migrations lock + DDL execution task.
    # -----------------------------------------------------------------------
    result =
      Ecto.Migrator.up(MigrationTestRepo, @migration_version, @migration_module, log: false)

    assert result in [:ok, :already_up],
           "Expected Ecto.Migrator.up to return :ok or :already_up, got: #{inspect(result)}"

    # -----------------------------------------------------------------------
    # Step 5: Query the row's claimed_at and lease_until via the direct
    # Postgrex connection (independent of MigrationTestRepo so we don't mix
    # concerns between the migration executor and the assertion reader).
    # -----------------------------------------------------------------------
    %{rows: [[claimed_at_db, lease_until_db]]} =
      Postgrex.query!(
        conn,
        "SELECT claimed_at, lease_until FROM #{@claims_table} WHERE id = $1",
        [Ecto.UUID.dump!(claim_id)]
      )

    # Postgrex returns NaiveDateTime for timestamp(6) without time zone columns.
    claimed_at_dt = DateTime.from_naive!(claimed_at_db, "Etc/UTC")
    lease_until_dt = DateTime.from_naive!(lease_until_db, "Etc/UTC")

    diff_seconds = DateTime.diff(lease_until_dt, claimed_at_dt, :second)

    # -----------------------------------------------------------------------
    # Step 6: Assert — lease_until = claimed_at + exactly 5 minutes (300s).
    # The migration SQL is: UPDATE ... SET lease_until = claimed_at + INTERVAL '5 minutes'
    # so the difference must be exactly 300 seconds.
    # -----------------------------------------------------------------------
    assert diff_seconds == 300,
           "Expected lease_until - claimed_at == 300s (5 min), got #{diff_seconds}s. " <>
             "claimed_at=#{claimed_at_dt}, lease_until=#{lease_until_dt}"
  end
end
