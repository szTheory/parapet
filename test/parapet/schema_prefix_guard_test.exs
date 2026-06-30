defmodule Parapet.SchemaPrefixGuardTest do
  use ExUnit.Case, async: true

  # PROP-02 static guard — scans lib/parapet/**/*.ex (NOT lib/mix/tasks/) for four
  # forbidden runtime-prefix shapes. Green from day one; fails the build with a
  # teaching message if any shape is reintroduced.
  #
  # D-02: Path.wildcard("lib/parapet/**/*.ex") does NOT match lib/mix/tasks/ — the
  # generator migration files legitimately contain create table(:parapet_*) and
  # references(:parapet_*, on_delete: :delete_all). The glob is the only exclusion needed.

  @lib_files Path.wildcard("lib/parapet/**/*.ex")

  # D-03 forbidden shapes — match the forbidden SHAPE, not the forbidden WORD:
  #
  #   (a) String/sigil literal immediately after insert_all/update_all/delete_all paren.
  #       Fires on: insert_all("parapet_claims", ...), update_all("parapet_x", ...)
  #       Does NOT fire on: insert_all(ActionClaim, ...), on_delete: :delete_all
  #
  #   (b) Bare repo `prefix:` option. Negative lookbehinds exclude:
  #         schema_prefix:   (schema configuration key)
  #         module_prefix    (module naming conventions)
  #         _prefix:         (any other _prefix: key)
  #         `prefix:`        (doc-string mentions, e.g. "Runtime `prefix:` is BANNED")
  #       Requires a space after the colon (option keyword pattern).
  #
  #   (c) search_path — any use of Postgres search_path switching in library code.
  #
  #   (d) parapet_ inside a fragment( call — raw SQL naming a prefixed table, e.g.
  #       fragment("parapet_incidents.id = ?", ...).
  @forbidden_patterns [
    # (a)
    {~r/(insert_all|update_all|delete_all)\s*\(\s*["~]/, :string_table_write,
     "Remove the string/sigil table literal. Pass the schema module (e.g. ActionClaim) instead."},
    # (b)
    {~r/(?<!schema_)(?<!module_)(?<!_)(?<!`)prefix:\s/, :bare_prefix_option,
     "Remove the runtime prefix: option. The compile-time @schema_prefix propagates automatically."},
    # (c)
    {~r/search_path/, :search_path,
     "Remove search_path usage. Schema routing is handled by @schema_prefix at compile time."},
    # (d)
    {~r/fragment\(.*parapet_/, :raw_sql_parapet,
     "Remove the raw parapet_ table name from the fragment(). Reference the schema module instead."}
  ]

  test "PROP-02: no runtime prefix options, string-table writes, search_path, or raw parapet_ SQL in lib/parapet/" do
    offenders =
      for file <- @lib_files,
          {:ok, source} <- [File.read(file)],
          {line_content, line_number} <-
            source |> String.split("\n") |> Enum.with_index(1),
          # Strip trailing inline comment (content after a bare # not inside a string)
          stripped = strip_trailing_comment(line_content),
          # Skip lines that are legitimate uses of _prefix: or schema_prefix:
          not (stripped =~ ~r/schema_prefix:/ or stripped =~ ~r/_prefix:/),
          {pattern, label, fix} <- @forbidden_patterns,
          stripped =~ pattern do
        %{file: file, line: line_number, pattern: label, code: String.trim(line_content), fix: fix}
      end

    assert offenders == [],
           format_guard_failure(offenders)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Strips a trailing # comment from a line. Handles the common case of a `#`
  # outside of string delimiters. Not a full Elixir parser — sufficient for the
  # four fingerprints this guard checks (none of which fire inside strings that
  # themselves contain #).
  defp strip_trailing_comment(line) do
    case Regex.run(~r/^([^#"]*)/, line) do
      [_, before_hash] -> before_hash
      _ -> line
    end
  end

  defp format_guard_failure(offenders) do
    offender_lines =
      offenders
      |> Enum.map(fn %{file: f, line: l, pattern: p, code: c, fix: fix} ->
        """
          #{f}:#{l}
          Pattern  : #{p}
          Code     : #{c}
          Fix      : #{fix}
        """
      end)
      |> Enum.join("\n")

    """

    ╔══════════════════════════════════════════════════════════════════════════╗
    ║           PROP-02 SCHEMA PREFIX GUARD VIOLATION                        ║
    ╚══════════════════════════════════════════════════════════════════════════╝

    WHY THIS FAILS — THE READ/WRITE SPLIT-BRAIN
    ============================================

    Parapet resolves the Postgres schema prefix at COMPILE TIME via
    Application.compile_env(:parapet, :schema_prefix, "parapet"), freezing it
    into module attributes (@schema_prefix on each spine schema, @prefix in
    ConcurrencyBootstrap, __prefix__/0 on Parapet.Spine.Schema).

    Ecto's prefix precedence is:

      1. FROM / JOIN clause prefix (highest — per-query override)
      2. @schema_prefix on the schema module (compile-time, Parapet's mechanism)
      3. prefix: option on the Repo call (runtime, BANNED in Parapet)
      4. Repo-level :prefix config (lowest)

    When a developer threads a runtime prefix: option into a Repo call, reads
    and writes can resolve to DIFFERENT Postgres schemas:

      • Reads use @schema_prefix (level 2) on the FROM/JOIN schemas
      • The runtime prefix: (level 3) may override writes differently

    This creates a split-brain where INSERT lands in "myschema".parapet_incidents
    but SELECT reads from "parapet".parapet_incidents — silent data divergence,
    no error raised, tests pass because they see neither schema.

    Similarly, raw search_path switching, string-literal table names in bulk
    writes (bypassing schema routing), and raw parapet_ names in fragment()
    calls all pierce the compile-time isolation contract.

    OFFENDERS (#{length(offenders)})
    =================================

    #{offender_lines}
    HOW TO FIX
    ==========

    1. Remove runtime prefix: options — the compile-time @schema_prefix on each
       schema module propagates automatically through Ecto's query builder.
    2. Replace string-literal table names with schema modules:
         insert_all("parapet_claims", rows)  →  insert_all(ActionClaim, rows)
    3. Remove search_path calls — Parapet does not switch search_path at runtime.
    4. Reference schema modules in queries instead of raw parapet_ SQL names.

    See lib/parapet/spine/schema.ex and the PROP-02 guard in
    test/parapet/schema_prefix_guard_test.exs for the authoritative boundary.
    """
  end
end
