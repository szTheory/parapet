defmodule Parapet do
  @moduledoc """
  Parapet provides telemetry foundations and safety rails for Phoenix SaaS teams.

  This top-level API provides boundary constraints ensuring that metric collection
  bugs never crash the host process and high cardinality labels are explicitly rejected.
  """
  require Logger

  alias Parapet.Internal.SafeHandler

  @doc """
  Attaches an exception-safe telemetry handler.

  Delegates to Parapet.Internal.SafeHandler to ensure errors in the callback
  do not propagate back to the execution of the instrumented application code.
  """
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
