defmodule Parapet.Escalation.Policy do
  @moduledoc """
  Behaviour for incident escalation adapters.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. Its public API will not change without a
  > major-version bump and a full deprecation cycle. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @doc since: "1.0.0"
  @doc """
  Escalates the given incident according to this adapter's escalation logic.
  """
  @callback escalate(incident :: Parapet.Spine.Incident.t(), opts :: keyword()) ::
              {:ok, term()} | {:error, term()}
end
