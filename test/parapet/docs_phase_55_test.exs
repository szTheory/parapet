defmodule Parapet.DocsPhase55Test do
  # Phase 55 shift-left: encodes the four human-judgment UAT checkpoints for the
  # single-source schema-prefix upgrade docs as deterministic assertions so the
  # phase advances on green CI with zero manual verification. Runs untagged in the
  # default `mix test` suite (all CI legs); a failure blocks `release_gate`.
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)

  @upgrade "docs/upgrade-1.x.md"

  # (table name, canonical schema module) — the six spine tables the move migration
  # relocates. Cross-referenced so a rename in either place, or a doc that drifts from
  # the generator, fails CI.
  @spine_tables [
    {"parapet_action_items", "lib/parapet/spine/action_item.ex"},
    {"parapet_incidents", "lib/parapet/spine/incident.ex"},
    {"parapet_timeline_entries", "lib/parapet/spine/timeline_entry.ex"},
    {"parapet_tool_audits", "lib/parapet/spine/tool_audit.ex"},
    {"parapet_system_events", "lib/parapet/spine/system_event.ex"},
    {"parapet_action_claims", "lib/parapet/spine/action_claim.ex"}
  ]

  defp read!(path), do: File.read!(Path.join(@root, path))

  defp heading_level(line) do
    case Regex.run(~r/^(#+) /, line) do
      [_, hashes] -> String.length(hashes)
      _ -> nil
    end
  end

  # Slice a doc from an exact heading line to (not including) the next heading of the
  # same or higher level. Used for "within this subsection" presence/refutation checks.
  defp section(doc, header) do
    level = heading_level(header)
    lines = String.split(doc, "\n")

    case Enum.find_index(lines, &(&1 == header)) do
      nil ->
        flunk("heading not found: #{inspect(header)}")

      start ->
        body =
          lines
          |> Enum.drop(start + 1)
          |> Enum.take_while(fn line ->
            lvl = heading_level(line)
            lvl == nil or lvl > level
          end)

        Enum.join([header | body], "\n")
    end
  end

  defp count(doc, regex), do: Regex.scan(regex, doc) |> length()

  # ── UAT #1: upgrade-1.x.md structure ─────────────────────────────────────────
  describe "upgrade-1.x.md structure (UAT 1)" do
    test "rollback covers Track A, Track B, and half-migrated recovery" do
      doc = read!(@upgrade)

      assert doc =~ "### Track A Rollback"
      assert doc =~ "### Track B Rollback"
      assert doc =~ "### Half-Migrated Recovery"
    end

    test "half-migrated recovery explains the single-transaction atomicity guarantee" do
      sec = read!(@upgrade) |> section("### Half-Migrated Recovery")

      assert sec =~ ~r/single transaction/i
      assert sec =~ ~r/rolls back all|atomic/i
    end

    test "FAQ is substantive and answers the do-nothing upgrader scenario" do
      doc = read!(@upgrade)

      assert doc =~ "## FAQ"
      assert count(doc, ~r/\*\*Q:/) >= 5
      assert doc =~ ~r/if i do nothing/i
    end

    test "every config :parapet block is followed by the force-recompile command in-section" do
      doc = read!(@upgrade)
      lines = String.split(doc, "\n")

      config_idxs =
        lines
        |> Enum.with_index()
        |> Enum.filter(fn {l, _} -> l =~ "config :parapet, schema_prefix" end)
        |> Enum.map(fn {_, i} -> i end)

      assert config_idxs != [], "no config :parapet blocks found in #{@upgrade}"

      # Not literal adjacency: a prose line ("Then recompile…") sits between the config
      # fence and the compile fence. The invariant is that the recompile command follows
      # within the same subsection (a small window), so a deleted recompile step fails CI.
      for i <- config_idxs do
        window = Enum.slice(lines, i, 12)

        assert Enum.any?(window, &(&1 =~ "mix deps.compile parapet --force")),
               "config :parapet at line #{i + 1} is not followed by " <>
                 "`mix deps.compile parapet --force` within 12 lines"
      end
    end

    test "recompile command appears throughout the guide (mass-deletion floor)" do
      doc = read!(@upgrade)
      assert count(doc, ~r/mix deps\.compile parapet --force/) >= 6
    end
  end

  # ── UAT #2: cross-source consistency + honest tone ───────────────────────────
  describe "upgrade-1.x.md tone and cross-source consistency (UAT 2)" do
    test "TL;DR leads with a data-never-moves reassurance" do
      sec = read!(@upgrade) |> section("## TL;DR")
      assert sec =~ ~r/data never moves/i
    end

    test "action-required framing is honest (does not falsely claim no action)" do
      doc = read!(@upgrade)

      assert doc =~ "## Action Required for Existing Adopters"
      refute doc =~ ~r/no action (is )?required/i
    end

    test "Track A config line matches the schema module source of truth" do
      doc = read!(@upgrade)
      schema_src = read!("lib/parapet/spine/schema.ex")

      assert doc =~ "config :parapet, schema_prefix: nil"
      assert schema_src =~ "config :parapet, schema_prefix: nil"
    end

    test "recompile command matches the doctor drift-message source of truth" do
      doc = read!(@upgrade)
      doctor_src = read!("lib/mix/tasks/parapet.doctor.ex")

      assert doc =~ "mix deps.compile parapet --force"
      assert doctor_src =~ "mix deps.compile parapet --force"
    end

    test "the six ALTER TABLE ... SET SCHEMA lines match the move generator and schema modules" do
      doc = read!(@upgrade)
      gen_src = read!("lib/mix/tasks/parapet.gen.schema.move.ex")

      for {table, module_path} <- @spine_tables do
        # Rendered form in the doc (resolved schema == parapet).
        assert doc =~ "ALTER TABLE public.#{table} SET SCHEMA parapet",
               "doc missing rendered ALTER TABLE line for #{table}"

        # Template form in the generator (schema interpolated as #{resolved}).
        assert gen_src =~ "ALTER TABLE public.#{table} SET SCHEMA",
               "generator missing ALTER TABLE line for #{table}"

        # Canonical table name still declared by its Ecto schema module.
        assert read!(module_path) =~ "schema \"#{table}\"",
               "#{module_path} no longer declares schema #{table}"
      end
    end

    test "least-privilege GRANT copy is present (verbs + target schema)" do
      # Presence, not byte-equality: the doc's GRANT block intentionally renders
      # differently from lib/parapet/spine/schema_move_notice.ex (spacing, trailing
      # comments). True single-sourcing of the GRANT copy is tracked separately.
      sec = read!(@upgrade) |> section("## Least-Privilege GRANTs (DBA-Managed Schema)")

      assert sec =~ ~r/GRANT USAGE/
      assert sec =~ "GRANT CREATE ON SCHEMA parapet"
    end
  end

  # ── UAT #3: deployment.md single-source compliance ───────────────────────────
  describe "deployment.md single-source compliance (UAT 3)" do
    test "Schema location subsection routes to the upgrade guide without restating mechanics" do
      sec = read!("docs/deployment.md") |> section("### Schema location")

      assert sec =~ "upgrade-1.x.md"

      refute sec =~ "config :parapet"
      refute sec =~ "ALTER TABLE"
      refute sec =~ ~r/GRANT /
      refute sec =~ "mix deps.compile"
    end
  end

  # ── UAT #4: README schema note placement & tone ──────────────────────────────
  describe "README schema note placement and tone (UAT 4)" do
    test "note routes to migration-v1.md Step 3, sits after the install block, restates no mechanics" do
      rd = read!("README.md")

      # Routes correctly.
      assert rd =~ "docs/migration-v1.md"
      assert rd =~ "Step 3"

      {install_off, _} = :binary.match(rd, "mix parapet.install")
      {note_off, _} = :binary.match(rd, "New installations default")

      # Placement: the schema note follows the install block.
      assert install_off < note_off

      # Brief / reassuring proxy: no mechanics restated between the install block and the note.
      between = binary_part(rd, install_off, note_off - install_off)
      refute between =~ "config :parapet"
      refute between =~ "ALTER TABLE"
    end

    test "migration-v1.md has the Step 3 schema-location step among seven steps" do
      mig = read!("docs/migration-v1.md")

      assert mig =~ "## Step 3: Choose your schema location"
      assert count(mig, ~r/^## Step /m) == 7
    end
  end
end
