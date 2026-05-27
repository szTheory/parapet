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
      # Tear down: restore the DB to a clean state for subsequent test runs.

      # Remove this migration's schema_migrations record.
      Postgrex.query!(conn, "DELETE FROM schema_migrations WHERE version = $1", [
        @migration_version
      ])

      # Re-add the lease_until column if the test left it dropped.
      Postgrex.query!(
        conn,
        "ALTER TABLE parapet_action_claims ADD COLUMN IF NOT EXISTS lease_until timestamp(6) without time zone",
        []
      )

      # Backfill any rows missing lease_until (safety for the NOT NULL restoration).
      Postgrex.query!(
        conn,
        "UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes' WHERE lease_until IS NULL",
        []
      )

      # Re-create the partial index if the migration dropped it via rollback.
      Postgrex.query!(
        conn,
        "CREATE INDEX IF NOT EXISTS parapet_action_claims_lease_until_claimed_index ON parapet_action_claims (lease_until) WHERE status = 'claimed'",
        []
      )

      # Remove test rows so successive runs are deterministic.
      Postgrex.query!(
        conn,
        "DELETE FROM parapet_action_claims WHERE action_key = 'migration-backfill-test'",
        []
      )

      Postgrex.query!(
        conn,
        "DELETE FROM parapet_incidents WHERE title = 'migration-backfill-verify'",
        []
      )

      # Clean up schema_migrations table (kept pristine across runs).
      Postgrex.query!(conn, "DROP TABLE IF EXISTS schema_migrations", [])

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
      "DROP INDEX IF EXISTS parapet_action_claims_lease_until_claimed_index",
      []
    )

    Postgrex.query!(
      conn,
      "ALTER TABLE parapet_action_claims DROP COLUMN IF EXISTS lease_until",
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
      "INSERT INTO parapet_incidents (id, title, state, runbook_data, inserted_at, updated_at) " <>
        "VALUES ($1, 'migration-backfill-verify', 'open', '{}', $2, $2)",
      [Ecto.UUID.dump!(incident_id), now]
    )

    claim_id = Ecto.UUID.generate()
    # claimed_at is 10 minutes in the past — a realistic crashed-node scenario.
    claimed_at = DateTime.add(now, -10 * 60, :second) |> DateTime.truncate(:microsecond)

    Postgrex.query!(
      conn,
      "INSERT INTO parapet_action_claims " <>
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
        "SELECT claimed_at, lease_until FROM parapet_action_claims WHERE id = $1",
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
