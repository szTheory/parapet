defmodule Parapet.Spine.Schema.Normalizer do
  @moduledoc false

  # safe_ident!/1 and normalize/1 are defined in this private submodule so they
  # can be called from the @prefix module attribute in Parapet.Spine.Schema.
  # Elixir evaluates module attributes at compile time but cannot call functions
  # from the module currently being compiled — defining them in a submodule that
  # is compiled first works around this constraint without any magic.
  #
  # Public API lives on Parapet.Spine.Schema via defdelegate (see below).

  @doc false
  def safe_ident!(ident) do
    unless ident =~ ~r/^[a-z_][a-z0-9_]*$/ and byte_size(ident) <= 63 do
      raise ArgumentError,
            "Invalid Postgres schema identifier: #{inspect(ident)}. " <>
              "Must match ^[a-z_][a-z0-9_]*$, max 63 bytes."
    end

    ident
  end

  @doc false
  def normalize(p) when p in [nil, "", "public"], do: nil
  def normalize(other) when is_atom(other), do: normalize(Atom.to_string(other))
  def normalize(other) when is_binary(other), do: safe_ident!(other)
end

defmodule Parapet.Spine.Schema do
  @moduledoc """
  Shared base macro for all Parapet spine schemas. Replaces `use Ecto.Schema`.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** as of v1.7.0. The `use Parapet.Spine.Schema` macro
  > interface and the prefix normalization API (`normalize/1`, `safe_ident!/1`) may evolve
  > as the schema-isolation story matures. See
  > [Stability & Deprecation Policy](stability.html) for details.

  Centralizes the Postgres schema prefix — the single place the prefix is named in library
  code. Resolved at COMPILE TIME from `config :parapet, :schema_prefix` (default `"parapet"`).

  `nil`, `""`, and `"public"` all mean "no prefix" (legacy/public-schema behavior).
  Unset env defaults to `"parapet"`; explicit `nil`/`""`/`"public"` means unprefixed
  (the "absence = default, explicit nil = off" contract).
  Runtime `prefix:` is BANNED — it creates a read/write precedence split-brain where reads and
  writes can land in different schemas. The compile-time `@schema_prefix` mechanism guarantees
  agreement by construction.

  ## Usage

      defmodule Parapet.Spine.SomeTable do
        use Parapet.Spine.Schema

        schema "parapet_some_tables" do
          # ...
        end
      end

  ## Configuration

  Host applications that want to keep Parapet tables in `public` (legacy behavior) should set:

      config :parapet, schema_prefix: nil

  This must be set BEFORE the library is compiled (`mix deps.compile parapet --force` after changing).
  """

  # normalize/1 and safe_ident!/1 are the single canonical normalization path for the
  # prefix value. They live in Parapet.Spine.Schema.Normalizer (a private compile-only
  # submodule defined above in this file) so they can be called from the @prefix module
  # attribute below. The public API is exposed on this module via defdelegate.

  @doc false
  defdelegate normalize(p), to: Parapet.Spine.Schema.Normalizer
  @doc false
  defdelegate safe_ident!(ident), to: Parapet.Spine.Schema.Normalizer

  # Read the configured prefix at compile time (module attribute — this is the only
  # place Application.compile_env/3 may appear; inside a def body it raises).
  @raw_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")

  # Single normalization source: Normalizer.normalize/1 + safe_ident!/1 replaces
  # the previously inline case block. The Normalizer submodule is compiled first
  # (defined above in this file), so it is available when this module attribute fires.
  @prefix Parapet.Spine.Schema.Normalizer.normalize(@raw_prefix)

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @schema_prefix Parapet.Spine.Schema.__prefix__()
    end
  end

  @doc false
  def __prefix__ do
    @prefix
  end

  @doc """
  Generate-time prefix resolver — reads the `--schema` flag and adopter config to
  produce the prefix literal that generators interpolate into migration heredocs.

  This is the generate-time counterpart to `__prefix__/0`:

  - `__prefix__/0` is the **compile-time** reader: it resolves `compile_env` once when
    the library is compiled and returns a frozen value. It is the correct tool for Ecto
    schema `@schema_prefix` and any code that runs inside the compiled library.

  - `resolve_prefix/2` is the **generate-time** reader: it reads the operator's live
    `Application.get_env/3` config (which may differ from what the library was last
    compiled with) and the `--schema` CLI flag, applies precedence
    `flag > existing config > default "parapet"` (D-06), and returns either
    `{:ok, normalized}` or `{:conflict, normalized_flag, normalized_config}`.

  **Do not cross the streams.** `resolve_prefix/2` must never call `__prefix__/0`,
  read `@prefix`, or use `Application.compile_env/3`. Generators use `resolve_prefix/2`
  to produce a literal prefix that is baked into the emitted migration source; that
  literal is what gets compiled later by the adopter's app.

  ## Arguments

  - `flag` — the `--schema` option value from the mix task CLI args, or `nil` if absent.
  - `existing_config` — the current value of `Application.get_env(:parapet, :schema_prefix)`,
    or `nil` if unset.

  Both arguments are normalized through `normalize/1` → `safe_ident!/1` before any
  comparison or return. A malformed identifier raises `ArgumentError` before the function
  can produce a result (ASVS V5 / T-53-01 mitigation).

  ## Return values

  - `{:ok, normalized}` — a single agreed-upon prefix string, or `nil` for the legacy/
    public-schema leg (when both normalize to nil, the default `"parapet"` is returned).
  - `{:conflict, normalized_flag, normalized_config}` — the flag and config disagree;
    `normalized_flag` wins for this generate run, but the caller should emit an
    `Igniter.add_warning/2` instructing the operator to reconcile `config/config.exs`
    and re-compile. This function never clobbers config and never crashes on a conflict.

  ## Precedence

  `flag > existing config > default "parapet"` — once both values are normalized, the
  flag takes priority. Agreement and single-source cases collapse to `{:ok, _}`. Only a
  genuinely divergent non-nil pair produces `{:conflict, _, _}`.
  """
  def resolve_prefix(flag, existing_config) do
    # Both paths run through normalize/1 → safe_ident!/1.
    # A malformed identifier raises ArgumentError here, before any return.
    normalized_flag = if flag, do: normalize(flag), else: nil
    normalized_config = if existing_config, do: normalize(existing_config), else: nil

    cond do
      # Both absent: return the default. Calling normalize("parapet") ensures the default
      # itself is allowlist-checked and that D-00 (single normalization source) holds.
      is_nil(normalized_flag) and is_nil(normalized_config) ->
        {:ok, normalize("parapet")}

      # Flag absent: use the existing config value.
      is_nil(normalized_flag) ->
        {:ok, normalized_config}

      # Config absent: use the flag value.
      is_nil(normalized_config) ->
        {:ok, normalized_flag}

      # Both present and equal: agreement.
      normalized_flag == normalized_config ->
        {:ok, normalized_flag}

      # Both present and different: conflict. Flag wins for this run; the caller warns.
      # This function never clobbers config and never raises on a conflict.
      true ->
        {:conflict, normalized_flag, normalized_config}
    end
  end

  @doc """
  Igniter-aware arity of `resolve_prefix/2`. Extracts the `--schema` flag from
  `igniter.args.options[:schema]` and the existing config from
  `Application.get_env(:parapet, :schema_prefix)`, then delegates to the pure core.

  Callers that need to emit a warning on conflict should pattern-match the return value:

      case Parapet.Spine.Schema.resolve_prefix(igniter) do
        {:ok, prefix} -> ...
        {:conflict, prefix, existing} ->
          igniter
          |> Igniter.add_warning(
               "--schema <flag> conflicts with config :parapet, :schema_prefix <existing>. " <>
               "The flag value will be used for this run. To reconcile, update config/config.exs and " <>
               "run: mix deps.compile parapet --force")
          |> then(fn igniter -> {igniter, prefix} end)
      end

  This arity is intentionally a thin reader. The `Igniter.add_warning/2` call belongs
  in the mix task that has an `igniter` struct to thread.
  """
  def resolve_prefix(igniter) do
    flag = igniter.args.options[:schema]
    existing_config = Application.get_env(:parapet, :schema_prefix)
    resolve_prefix(flag, existing_config)
  end
end
