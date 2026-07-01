defmodule Parapet.GenSchemaMoveGoldenTest do
  @moduledoc """
  DB-less golden test for the committed move migration fixture (UPG-02).

  Snapshots the migration body shape of the committed fixture:
    priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs

  This is the SAME file that the round-trip test (Plan 03) executes against a
  throwaway DB — so the golden and the round-trip tests cannot drift (D-13,
  Pitfall 5). Any change to the fixture body will make this test fail first,
  telling the author which shape assertions to update.

  Assertions prove the UPG-02 / D-08 body contract:
    (a) exactly SIX `SET SCHEMA parapet` lines (up direction)
    (b) exactly SIX `SET SCHEMA public` lines (down direction)
    (c) `after_begin` is present
    (d) `SET LOCAL lock_timeout` is present
    (e) `@disable_ddl_transaction` is absent (would break atomicity + no-op SET LOCAL)
    (f) `DROP SCHEMA` is absent (fail-closed, never in down)
    (g) the migrate-time RAISE EXCEPTION abort guard is present
    (h) `to_regclass('public.'` (abort guard injection-safe form) is present
  """

  use ExUnit.Case, async: true

  @fixture_path Path.join([
                  __DIR__,
                  "../../priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs"
                ])

  setup_all do
    {:ok, source} = File.read(@fixture_path)
    {:ok, source: source}
  end

  # ---------------------------------------------------------------------------
  # (a) six explicit SET SCHEMA parapet lines (up direction)
  # ---------------------------------------------------------------------------

  test "contains exactly six ALTER TABLE ... SET SCHEMA parapet lines (up)", %{source: source} do
    count =
      source
      |> String.split("\n")
      |> Enum.count(&(&1 =~ ~r/SET SCHEMA parapet/))

    assert count == 6,
           "Expected exactly 6 'SET SCHEMA parapet' lines (one per spine table, D-08), got #{count}.\n" <>
             "Source:\n#{source}"
  end

  # ---------------------------------------------------------------------------
  # (b) six explicit SET SCHEMA public lines (down direction)
  # ---------------------------------------------------------------------------

  test "contains exactly six ALTER TABLE ... SET SCHEMA public lines (down)", %{source: source} do
    count =
      source
      |> String.split("\n")
      |> Enum.count(&(&1 =~ ~r/SET SCHEMA public/))

    assert count == 6,
           "Expected exactly 6 'SET SCHEMA public' lines (LIFO down direction, D-08), got #{count}.\n" <>
             "Source:\n#{source}"
  end

  # ---------------------------------------------------------------------------
  # (c) after_begin callback present
  # ---------------------------------------------------------------------------

  test "defines after_begin/0 for transaction-scoped lock_timeout", %{source: source} do
    assert source =~ "after_begin",
           "Expected after_begin/0 callback in the fixture (D-08 Pattern 3)"
  end

  # ---------------------------------------------------------------------------
  # (d) SET LOCAL lock_timeout present
  # ---------------------------------------------------------------------------

  test "body includes SET LOCAL lock_timeout", %{source: source} do
    assert source =~ "SET LOCAL lock_timeout",
           "Expected 'SET LOCAL lock_timeout' inside after_begin (D-08)"
  end

  # ---------------------------------------------------------------------------
  # (e) @disable_ddl_transaction is ABSENT (would break atomicity + no-op SET LOCAL)
  # ---------------------------------------------------------------------------

  test "does NOT contain @disable_ddl_transaction (would break atomicity)", %{source: source} do
    refute source =~ "@disable_ddl_transaction",
           "Fixture must NOT set @disable_ddl_transaction (D-08 — breaks single-transaction guarantee)"
  end

  # ---------------------------------------------------------------------------
  # (f) DROP SCHEMA is ABSENT in execute() calls (fail-closed down direction)
  # ---------------------------------------------------------------------------

  test "does NOT contain execute(DROP SCHEMA ...) in down direction (fail-closed)", %{
    source: source
  } do
    # Strip comment lines before checking — the fixture has a deliberate comment
    # that says "no DROP SCHEMA" to explain the design. We only forbid the actual
    # executable SQL form: execute("DROP SCHEMA") or execute("""DROP SCHEMA...""").
    lines_without_comments =
      source
      |> String.split("\n")
      |> Enum.reject(&String.match?(String.trim(&1), ~r/^#/))
      |> Enum.join("\n")

    refute lines_without_comments =~ ~r/execute\([^)]*DROP SCHEMA/s,
           "down/0 must NEVER execute DROP SCHEMA (D-08 fail-closed; T-54-06 threat mitigation)"
  end

  # ---------------------------------------------------------------------------
  # (g) RAISE EXCEPTION abort guard present
  # ---------------------------------------------------------------------------

  test "contains the migrate-time RAISE EXCEPTION abort guard (D-10)", %{source: source} do
    assert source =~ "RAISE EXCEPTION",
           "Expected RAISE EXCEPTION abort guard in up/0 (D-10, UPG-03)"
  end

  # ---------------------------------------------------------------------------
  # (h) to_regclass injection-safe form present
  # ---------------------------------------------------------------------------

  test "abort guard uses to_regclass('public.' for injection-safe table check", %{source: source} do
    assert source =~ "to_regclass('public.'",
           "Expected to_regclass('public.' in the abort guard (D-10, T-54-05 — quote_ident path)"
  end

  # ---------------------------------------------------------------------------
  # Bonus: all six spine tables present in both directions
  # ---------------------------------------------------------------------------

  @six_tables ~w[
    parapet_action_items
    parapet_incidents
    parapet_timeline_entries
    parapet_tool_audits
    parapet_system_events
    parapet_action_claims
  ]

  test "all six spine tables appear in up direction (SET SCHEMA parapet)", %{source: source} do
    for table <- @six_tables do
      assert source =~ "ALTER TABLE public.#{table} SET SCHEMA parapet",
             "Expected 'ALTER TABLE public.#{table} SET SCHEMA parapet' in fixture"
    end
  end

  test "all six spine tables appear in down direction (SET SCHEMA public)", %{source: source} do
    for table <- @six_tables do
      assert source =~ "ALTER TABLE parapet.#{table} SET SCHEMA public",
             "Expected 'ALTER TABLE parapet.#{table} SET SCHEMA public' in fixture"
    end
  end
end
