defmodule Parapet.Probe do
  @moduledoc """
  Defines a behaviour for synthetic probes.

  Probes are active checks that maintain SLO signal quality by running
  periodic business logic.
  """

  @callback run() :: :ok | {:error, term()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Parapet.Probe

      def execute do
        :telemetry.span([:parapet, :probe, :run], %{probe: inspect(__MODULE__)}, fn ->
          case run() do
            :ok ->
              {:ok, %{probe: inspect(__MODULE__), status: "success"}}

            {:error, reason} = error ->
              {error, %{probe: inspect(__MODULE__), status: "error"}}
          end
        end)
      end
    end
  end
end
