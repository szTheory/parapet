defmodule Parapet.Internal.SafeHandler do
  @moduledoc false
  require Logger

  def attach(handler_id, event_name, handler_module, function_name, config \\ %{}) do
    :telemetry.attach(
      handler_id,
      event_name,
      fn event, measurements, metadata, conf ->
        try do
          apply(handler_module, function_name, [event, measurements, metadata, conf])
        rescue
          e ->
            Logger.error(
              "Parapet telemetry handler exception in #{inspect(handler_module)}.#{function_name}/4: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}",
              event: event
            )
        end
      end,
      config
    )
  end
end
