defmodule Parapet.Spine.Schema do
  @moduledoc """
  Shared base macro for all Parapet spine schemas. Replaces `use Ecto.Schema`.

  Centralizes the Postgres schema prefix — the single place the prefix is named in library
  code. Resolved at COMPILE TIME from `config :parapet, :schema_prefix` (default `"parapet"`).

  `nil`, `""`, and `"public"` all mean "no prefix" (legacy/public-schema behavior).
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

  # Read the configured prefix at compile time (module attribute — this is the only
  # place Application.compile_env/3 may appear; inside a def body it raises).
  @raw_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")

  # Normalize: nil / "" / "public" → nil (unprefixed); binary → itself; atom → string.
  # This is one of the two physical copies of the D-05 normalization rule. The other lives
  # in config/config.exs. A unit test (schema_test.exs "normalization agreement" block)
  # asserts both copies map the canonical input set identically.
  @prefix (case @raw_prefix do
             p when p in [nil, "", "public"] -> nil
             other when is_binary(other) -> other
             other when is_atom(other) -> Atom.to_string(other)
           end)

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
