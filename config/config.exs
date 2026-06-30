import Config

# Compile-time Postgres schema prefix for all six Parapet spine tables.
#
# Set PARAPET_SCHEMA_PREFIX to control the prefix:
#   unset / nil   → "parapet"  (default — new installs live in the parapet schema)
#   ""            → nil        (unprefixed; legacy public-schema behavior)
#   "public"      → nil        (alias for unprefixed; same as "")
#   any other     → itself     (custom schema name)
#
# This normalization is physically duplicated in Parapet.Spine.Schema.__prefix__/0
# (which runs at compile time via Application.compile_env). The two copies MUST agree
# on the canonical input set ["parapet","","public",nil,"custom"]; the unit test
# in test/parapet/spine/schema_test.exs ("normalization agreement" describe block)
# is the only guard against silent drift between them (D-05).
#
# NOTE: config is intentionally excluded from mix.exs package.files (D-07).
# Adopters must set their own config :parapet, schema_prefix in their host app.

schema_prefix =
  case System.get_env("PARAPET_SCHEMA_PREFIX") do
    nil -> "parapet"
    "" -> nil
    "public" -> nil
    other -> other
  end

config :parapet, schema_prefix: schema_prefix
