defmodule Parapet.Deploy do
  @moduledoc """
  API for emitting deployment markers as telemetry events.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. Its public API will not change without a
  > major-version bump and a full deprecation cycle. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @doc since: "1.0.0"
  @doc """
  Emits a `[:parapet, :deploy, :mark]` telemetry event.

  The measurements include `system_time: System.system_time(:millisecond)`.
  Any provided options are included as metadata.
  """
  @spec mark(keyword() | map()) :: :ok
  def mark(opts \\ []) do
    metadata = Map.new(opts)
    measurements = %{system_time: System.system_time(:millisecond)}

    :telemetry.execute([:parapet, :deploy, :mark], measurements, metadata)
  end
end
