defmodule Parapet.Repo.Migrations.AddLeaseUntilToParapetActionClaims do
  @moduledoc """
  Adds `lease_until` (NOT NULL) to `parapet_action_claims` and backfills
  existing rows with `claimed_at + INTERVAL '5 minutes'`.

  > #### Adopter note: production locking {: .warning}
  >
  > This migration runs three statements inside a single transaction:
  >
  > 1. `ALTER TABLE ... ADD COLUMN lease_until` (briefly acquires `ACCESS EXCLUSIVE`)
  > 2. `UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'`
  >    — full-table scan + rewrite, still holding the lock
  > 3. `ALTER TABLE ... ALTER COLUMN lease_until SET NOT NULL` — full-table scan
  >    to validate the constraint, still holding the lock
  >
  > Reads and writes against `parapet_action_claims` are blocked for the
  > duration of the scan. Adopters with **non-trivial existing claim history**
  > (i.e. millions of rows) should run this migration during a maintenance
  > window, or split it manually into the canonical online-migration pattern
  > (nullable ADD COLUMN → batched backfill → `NOT VALID` CHECK constraint →
  > separate `VALIDATE CONSTRAINT`). The single-transaction form is correct
  > and safe for typical adopter table sizes in the v1.x experimental window
  > (see `Parapet.Spine.ActionClaim` stability classification).

  ## Lease window

  The 5-minute backfill interval matches `Parapet.Automation.ClaimService`'s
  `@default_lease_ms = 5 * 60 * 1_000`. Keep these in sync — see IN-04 of
  the phase-23 code review for the rationale.
  """

  use Ecto.Migration

  @prefix Parapet.Spine.Schema.__prefix__()
  @table if @prefix, do: ~s("#{@prefix}"."parapet_action_claims"), else: "parapet_action_claims"

  def change do
    alter table(:parapet_action_claims, prefix: @prefix) do
      add :lease_until, :utc_datetime_usec, null: true
    end

    execute(
      "UPDATE #{@table} SET lease_until = claimed_at + INTERVAL '5 minutes'",
      ""
    )

    alter table(:parapet_action_claims, prefix: @prefix) do
      modify :lease_until, :utc_datetime_usec, null: false, from: {:utc_datetime_usec, null: true}
    end

    create index(:parapet_action_claims, [:lease_until],
             where: "status = 'claimed'",
             name: :parapet_action_claims_lease_until_claimed_index,
             prefix: @prefix
           )
  end
end
