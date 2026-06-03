defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for providing SLOs to the Parapet system.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. Its public API will not change without a
  > major-version bump and a full deprecation cycle. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @doc since: "1.0.0"
  @doc """
  Returns the list of `Parapet.SLO.SliceSpec` structs this provider registers.
  Called by Parapet during startup to build the active SLO registry.
  """
  @callback slos() :: [struct()]
end
