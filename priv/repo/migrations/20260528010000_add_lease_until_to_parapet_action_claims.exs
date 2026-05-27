defmodule Parapet.Repo.Migrations.AddLeaseUntilToParapetActionClaims do
  use Ecto.Migration

  def change do
    alter table(:parapet_action_claims) do
      add :lease_until, :utc_datetime_usec, null: true
    end

    execute(
      "UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'",
      ""
    )

    alter table(:parapet_action_claims) do
      modify :lease_until, :utc_datetime_usec, null: false, from: {:utc_datetime_usec, null: true}
    end

    create index(:parapet_action_claims, [:lease_until],
             where: "status = 'claimed'",
             name: :parapet_action_claims_lease_until_claimed_index
           )
  end
end
