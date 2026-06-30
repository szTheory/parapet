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
end
