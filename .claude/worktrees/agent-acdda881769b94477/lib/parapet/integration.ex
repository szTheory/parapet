defmodule Parapet.Integration do
  @moduledoc """
  Behaviour for Parapet ecosystem integration adapters.

  Every integration adapter that plugs into `Parapet.attach/1` implements this behaviour.
  Adopters activate an integration uniformly via:

      Parapet.attach(adapters: [:my_integration])

  Declaring `@behaviour Parapet.Integration` on an adapter module turns a missing or
  mis-named `setup/0` into a compile-time warning, preventing the `UndefinedFunctionError`
  that would otherwise surface only at runtime.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. Its public API will not change without a
  > major-version bump and a full deprecation cycle. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @doc since: "1.0.0"
  @doc """
  Sets up the integration adapter, attaching telemetry handlers and performing any
  required initialization. Called by `Parapet.attach/1` when this adapter is activated.
  """
  @callback setup() :: any()
end
