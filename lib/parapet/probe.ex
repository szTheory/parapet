defmodule Parapet.Probe do
  @moduledoc """
  Defines a behaviour for synthetic probes.

  Probes are active checks that maintain SLO signal quality by running
  periodic business logic.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
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
