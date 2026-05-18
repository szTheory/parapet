defmodule Parapet.Escalation.Policy do
  @moduledoc """
  Behaviour for incident escalation adapters.
  """

  @callback escalate(incident :: Parapet.Spine.Incident.t(), opts :: keyword()) ::
              {:ok, term()} | {:error, term()}
end
