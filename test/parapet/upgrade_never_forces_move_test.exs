defmodule Parapet.UpgradeNeverForcesMoveTest do
  @moduledoc false

  # UPG-05 static guard — pins two truths required by D-17/D-20:
  #
  # 1. Regex fitness function (D-20): proves the installer and generator source
  #    files NEVER reference `parapet.gen.schema.move` or the move module name
  #    `Mix.Tasks.Parapet.Gen.Schema.Move`. This goes red the day someone wires
  #    the move task into the auto-run installer path — preventing the D-17
  #    footgun where adopters would get a silent data migration on upgrade.
  #
  # 2. Default-prefix pin (D-20): `resolve_prefix(nil, nil) == {:ok, "parapet"}`
  #    pins the "default = parapet for new installs" literal. Fails if the
  #    default ever changes unnoticed.
  #
  # D-17 TRUTH: no runtime install-detection and there must not be one.
  # UPG-05's literal promise — "upgrading an existing adopter never forces a
  # schema migration" — is true ONLY as "no data migration is ever auto-run."
  # Track A adopters must explicitly set `config :parapet, schema_prefix: nil`
  # + `mix deps.compile parapet --force`.
  #
  # Clones the `schema_prefix_guard_test.exs` glob→read→line-scan→assert shape.

  use ExUnit.Case, async: true

  # The installer + generator source files that must never auto-chain the move task.
  # IMPORTANT: parapet.gen.schema.move itself is intentionally excluded — it
  # legitimately names the move module. Only the installer and gen.* tasks that
  # an adopter would run as part of initial setup or code generation are scanned.
  @installer_files [
    "lib/mix/tasks/parapet.install.ex",
    "lib/mix/tasks/parapet.gen.spine.ex",
    "lib/mix/tasks/parapet.gen.archive_indexes.ex"
  ]

  # Forbidden patterns — any reference to the move task in the installer path.
  # If either pattern fires, it means the move task has been wired into the
  # auto-run install/generation path — violating D-17 and silently forcing a
  # data migration on adopter upgrade.
  @forbidden_move_patterns [
    # Task module atom / dotted name: `parapet.gen.schema.move` or `parapet.schema.move`
    ~r/parapet\.(gen\.)?schema\.move/i,
    # Fully-qualified module reference: `Mix.Tasks.Parapet.Gen.Schema.Move`
    ~r/Mix\.Tasks\.Parapet\.Gen\.Schema\.Move/
  ]

  # ---------------------------------------------------------------------------
  # UPG-05 fitness function (D-20)
  # ---------------------------------------------------------------------------

  test "UPG-05: installer and gen tasks never reference the schema-move task (D-17, D-20)" do
    offenders =
      for file <- @installer_files,
          {:ok, source} <- [File.read(file)],
          {line_content, line_number} <-
            source |> String.split("\n") |> Enum.with_index(1),
          pattern <- @forbidden_move_patterns,
          line_content =~ pattern do
        %{file: file, line: line_number, pattern: inspect(pattern), code: String.trim(line_content)}
      end

    assert offenders == [],
           format_move_guard_failure(offenders)
  end

  # ---------------------------------------------------------------------------
  # Default-prefix pin (D-20)
  # ---------------------------------------------------------------------------

  test "UPG-05: resolve_prefix(nil, nil) == {:ok, \"parapet\"} (default for new installs, D-20)" do
    # Pins the "default = parapet for new installs" literal.
    # Fails if the default ever changes unnoticed — catching silent default drift
    # for new adopters (T-54-11 mitigation).
    assert Parapet.Spine.Schema.resolve_prefix(nil, nil) == {:ok, "parapet"}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp format_move_guard_failure(offenders) do
    offender_lines =
      offenders
      |> Enum.map(fn %{file: f, line: l, pattern: p, code: c} ->
        """
          #{f}:#{l}
          Pattern  : #{p}
          Code     : #{c}
        """
      end)
      |> Enum.join("\n")

    """

    ╔══════════════════════════════════════════════════════════════════════════╗
    ║           UPG-05 MOVE-TASK WIRING GUARD VIOLATION (D-17, D-20)         ║
    ╚══════════════════════════════════════════════════════════════════════════╝

    WHY THIS FAILS — THE SILENT DATA-MIGRATION FOOTGUN
    ===================================================

    Parapet's upgrade story (UPG-05, D-17) promises that upgrading an existing
    adopter NEVER automatically runs a schema-move data migration. The
    `mix parapet.gen.schema.move` task is deliberately OPT-IN — an adopter must
    explicitly run it, review the generated migration, and then run
    `mix ecto.migrate` at a time of their choosing.

    If the installer (`parapet.install`) or any generator task (`parapet.gen.*`)
    references or auto-chains the move task, this promise is broken:
    adopters who run `mix parapet.install` or `mix parapet.gen.spine` could
    trigger a schema-move data migration without knowing it, silently moving
    their production tables.

    This fitness function goes red the day the move task is wired into the
    installer path — preventing the footgun BEFORE it ships.

    For context on the upgrade story, see:
    - D-17 in .planning/phases/54-upgrade-path-doctor/54-RESEARCH.md
    - D-20 in .planning/phases/54-upgrade-path-doctor/54-RESEARCH.md

    OFFENDERS (#{length(offenders)})
    =================================

    #{offender_lines}
    HOW TO FIX
    ==========

    1. Remove the reference to `parapet.gen.schema.move` or
       `Mix.Tasks.Parapet.Gen.Schema.Move` from the flagged installer/generator.
    2. The move task must remain opt-in — called ONLY by the adopter explicitly.
    3. If you added a DX shortcut that chains the tasks, add a notice/warning
       instead of wiring the task directly:
         Igniter.add_notice(igniter, "Run `mix parapet.gen.schema.move` to generate
           a reversible migration that moves spine tables to the parapet schema.")

    See lib/mix/tasks/parapet.gen.schema.move.ex and D-17/D-20 in
    .planning/phases/54-upgrade-path-doctor/54-RESEARCH.md for the full boundary.
    """
  end
end
