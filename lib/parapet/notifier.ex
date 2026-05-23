defmodule Parapet.Notifier do
  @moduledoc """
  Behaviour for incident notification adapters.
  """
  @callback deliver(incident :: struct(), opts :: keyword()) :: {:ok, term()} | {:error, term()}

  def broadcast(incident) do
    notifiers = Application.get_env(:parapet, :notifiers, [])

    Enum.each(notifiers, fn {adapter, opts} ->
      dispatch(incident, adapter, opts)
    end)

    :ok
  end

  def dispatch(incident, adapter, opts) do
    oban = Oban
    worker = Parapet.Notifier.ObanWorker

    if Code.ensure_loaded?(oban) and
         Code.ensure_loaded?(worker) and
         function_exported?(oban, :insert, 1) and
         Application.get_env(:parapet, :use_oban_for_notifications, true) do
      args = %{
        "incident_id" => incident.id,
        "adapter" => to_string(adapter),
        "opts" => inspect(opts)
      }

      worker
      |> apply(:new, [args])
      |> then(&apply(oban, :insert, [&1]))
    else
      Task.start(fn ->
        deliver_and_audit(incident, adapter, opts)
      end)
    end
  end

  @doc false
  def deliver_and_audit(incident, adapter, opts) do
    {status, details} =
      try do
        case adapter.deliver(incident, opts) do
          {:ok, result} -> {"success", inspect(result)}
          {:error, reason} -> {"error", inspect(reason)}
          other -> {"error", inspect(other)}
        end
      rescue
        e -> {"error", inspect(e)}
      catch
        type, value -> {"error", "#{type}: #{inspect(value)}"}
      end

    attrs = %{
      type: "notification_dispatched",
      payload: %{
        adapter: inspect(adapter),
        status: status,
        details: details
      }
    }

    Parapet.Evidence.append_timeline(incident.id, attrs)

    if status == "error" do
      {:error, details}
    else
      :ok
    end
  end
end
