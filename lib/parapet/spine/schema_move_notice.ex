defmodule Parapet.Spine.SchemaMoveNotice do
  @moduledoc false

  # Single-source DBA least-privilege notice (D-12b / D-00).
  #
  # Both `mix parapet.gen.spine` (spine creation) and `mix parapet.gen.schema.move`
  # (table move) emit a DBA notice under `--no-create-schema`. The SQL body is
  # identical; only the trailing instruction line differs between the two contexts.
  #
  # Public API:
  #   emit_for_spine/3      — called by gen.spine (wording: "mix ecto.migrate to create the schema")
  #   emit_for_move/3       — called by gen.schema.move (wording: "mix ecto.migrate to move the spine")
  #
  # Guard: both functions are no-ops unless `create_schema == false` and `resolved` is non-nil.

  @doc false
  def emit_for_spine(igniter, _resolved, create_schema) when create_schema != false, do: igniter
  def emit_for_spine(igniter, nil, _create_schema), do: igniter

  def emit_for_spine(igniter, resolved, false) do
    Igniter.add_notice(
      igniter,
      dba_notice_body(resolved) <>
        "Then run: mix ecto.migrate  (no CREATE SCHEMA migration was generated)\n"
    )
  end

  @doc false
  def emit_for_move(igniter, _resolved, create_schema) when create_schema != false, do: igniter
  def emit_for_move(igniter, nil, _create_schema), do: igniter

  def emit_for_move(igniter, resolved, false) do
    Igniter.add_notice(
      igniter,
      dba_notice_body(resolved) <>
        "Then run: mix ecto.migrate to move the spine into #{resolved}  " <>
        "(no CREATE SCHEMA line was included in the move migration)\n"
    )
  end

  # Shared SQL body — the GRANT/AUTHORIZATION block identical for both contexts.
  defp dba_notice_body(resolved) do
    """
    Parapet schema setup (--no-create-schema): run once as a privileged role (DBA / schema owner):

      -- Happy path — schema owned by the app role:
      CREATE SCHEMA IF NOT EXISTS #{resolved} AUTHORIZATION your_app_role;

      -- Split-role fallback (schema owned by a separate role):
      GRANT USAGE  ON SCHEMA #{resolved} TO your_app_role;   -- resolve the schema
      GRANT CREATE ON SCHEMA #{resolved} TO your_app_role;   -- create tables/indexes during migrate

      -- Optional: narrow runtime role permissions (recommended for production)
      ALTER DEFAULT PRIVILEGES IN SCHEMA #{resolved}
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO your_app_runtime_role;

    """
  end
end
