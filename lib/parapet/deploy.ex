defmodule Parapet.Deploy do
  @moduledoc """
  API for emitting deployment markers as telemetry events.
  """

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
