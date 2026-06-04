defmodule Parapet.Internal.SafeHandler do
  @moduledoc false
  require Logger

  def attach(handler_id, event_name, handler_module, function_name, config \\ %{}) do
    :telemetry.attach(
      handler_id,
      event_name,
      &__MODULE__.handle_event/4,
      {handler_module, function_name, config}
    )
  end

  def handle_event(event, measurements, metadata, {handler_module, function_name, config}) do
    apply(handler_module, function_name, [event, measurements, metadata, config])
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{inspect(handler_module)}.#{function_name}/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
      )
  end
end
