defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for providing SLOs to the Parapet system.
  """

  @callback slos() :: [struct()]
end
