defmodule Parapet do
  @moduledoc """
  Parapet provides telemetry foundations and safety rails for Phoenix SaaS teams.

  This top-level API provides boundary constraints ensuring that metric collection
  bugs never crash the host process and high cardinality labels are explicitly rejected.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. Its public API will not change without a
  > major-version bump and a full deprecation cycle. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  require Logger

  alias Parapet.Internal.SafeHandler

  @doc since: "1.0.0"
  @doc """
  Attaches an exception-safe telemetry handler or activates ecosystem integration adapters.

  When a list with `:adapters` is provided, it iterates the adapter atoms, resolves the
  corresponding `Parapet.Integrations.*` module, and invokes `setup/0` on each loaded adapter
  module. All built-in integration adapters implement the `Parapet.Integration` behaviour, so
  `setup/0` is uniform across every adapter.

  When a map is provided, it delegates to Parapet.Internal.SafeHandler to ensure errors
  in the callback do not propagate back to the execution of the instrumented application code.
  """
  def attach(opts) when is_list(opts) do
    adapters = Keyword.get(opts, :adapters, [])

    Enum.each(adapters, fn adapter ->
      module_name =
        adapter
        |> to_string()
        |> Macro.camelize()

      module = Module.concat(Parapet.Integrations, module_name)

      if Code.ensure_loaded?(module) do
        apply(module, :setup, [])
      end
    end)

    {:ok, adapters}
  end

  def attach(
        %{
          handler_id: handler_id,
          event_name: event_name,
          handler_module: handler_module,
          function_name: function_name
        } = args
      ) do
    config = Map.get(args, :config, %{})

    unless Code.ensure_loaded?(:telemetry) do
      Logger.warning("Telemetry is missing, Parapet handler #{handler_id} cannot be attached.")
    end

    case SafeHandler.attach(
           handler_id,
           event_name,
           handler_module,
           function_name,
           config
         ) do
      :ok ->
        Logger.debug("Parapet attached telemetry handler #{handler_id}")
        {:ok, [handler_id]}

      {:error, _} = error ->
        error
    end
  end
end
