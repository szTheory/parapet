defmodule Parapet.Spine.CompiledPrefixLegTest do
  use ExUnit.Case, async: true

  # ---------------------------------------------------------------------------
  # D-14 / T-52-07 in-suite false-green tripwire
  #
  # This test asserts that the compiled __prefix__() matches the normalized
  # PARAPET_SCHEMA_PREFIX environment variable for THIS CI leg. It catches the
  # "_build cache false-green" defect: if the public CI leg restores the parapet
  # leg's _build cache, the schemas will carry "parapet" but the env says "" or
  # "public", and this assertion fails — exposing the false-green immediately.
  #
  # Defense layers (per TEST-03):
  #   Primary   — _build cache key namespaced by matrix.schema_prefix
  #   Secondary — mix compile --force before mix test
  #   Tertiary  — this in-suite guard (below)
  #   Free      — Elixir compile_env boot-check (never disabled; --no-validate-compile-env
  #               is NOT passed in CI)
  # ---------------------------------------------------------------------------

  # Read env at module-attribute level so it is captured at compile time of this
  # test module, mirroring the compile-time nature of Schema.__prefix__().
  @env_prefix System.get_env("PARAPET_SCHEMA_PREFIX", "parapet")

  # Frozen compiled prefix for this build — what the spine schemas actually carry.
  @compiled_prefix Parapet.Spine.Schema.__prefix__()

  test "compiled __prefix__() matches normalized PARAPET_SCHEMA_PREFIX env" do
    # Reuse the single-sourced normalizer (Schema.normalize/1) — do NOT re-implement
    # the normalization rule here. This ensures the test and production share one
    # normalization path, so a normalization change is caught automatically.
    expected = Parapet.Spine.Schema.normalize(@env_prefix)

    assert @compiled_prefix == expected,
           """
           Compiled prefix #{inspect(@compiled_prefix)} does not match \
           normalized env #{inspect(expected)} \
           (PARAPET_SCHEMA_PREFIX=#{inspect(@env_prefix)}).

           This usually means the _build cache was restored from a different CI leg:
             - The parapet leg compiled @schema_prefix = "parapet"
             - The public leg restored that same _build cache, inheriting "parapet"
             - This test (the tertiary tripwire) caught the false-green

           Remedies (both must be in place):
             1. Namespace the _build cache key by matrix.schema_prefix:
                key: ...-${{ matrix.schema_prefix }}-${{ hashFiles('**/mix.lock') }}
             2. Run `mix compile --force` before `mix test` on every CI leg
                so the PARAPET_SCHEMA_PREFIX env value is baked into _build.

           See: .planning/phases/52-propagation-proof-guards-ci-dual-prefix-matrix/52-RESEARCH.md
           (Pitfall 1 "_build Cache False-Green") and D-13/D-14 in 52-CONTEXT.md.
           """
  end
end
