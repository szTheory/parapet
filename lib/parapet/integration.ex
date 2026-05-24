defmodule Parapet.Integration do
  @moduledoc """
  Behaviour for Parapet ecosystem integration adapters.

  Every integration adapter that plugs into `Parapet.attach/1` implements this behaviour.
  Adopters activate an integration uniformly via:

      Parapet.attach(adapters: [:my_integration])

  Declaring `@behaviour Parapet.Integration` on an adapter module turns a missing or
  mis-named `setup/0` into a compile-time warning, preventing the `UndefinedFunctionError`
  that would otherwise surface only at runtime.
  """

  @callback setup() :: any()
end
