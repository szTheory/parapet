import Config

# Compile-time Postgres schema prefix for all six Parapet spine tables.
#
# Set PARAPET_SCHEMA_PREFIX to control the prefix:
#   unset / nil   → "parapet"  (default — new installs live in the parapet schema)
#   ""            → nil        (unprefixed; legacy public-schema behavior)
#   "public"      → nil        (alias for unprefixed; same as "")
#   any other     → itself     (custom schema name)
#
# Normalization contract: unset env defaults to "parapet"; explicit nil/""/
# "public" means unprefixed (the "absence = default, explicit nil = off" contract).
#
# This pre-compile copy is deliberately separate from Parapet.Spine.Schema.normalize/1
# (the single runtime normalization source). The two MUST agree on the canonical input
# set ["parapet","","public",nil,"custom"] → ["parapet",nil,nil,nil,"custom"];
# the unit test in test/parapet/spine/schema_test.exs ("normalization agreement" block)
# drives normalize/1 directly to verify this.
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
