defmodule Parapet.Notifier do
  @callback deliver(incident :: Parapet.Spine.Incident.t(), opts :: keyword()) :: {:ok, term()} | {:error, term()}

  def broadcast(incident) do
    notifiers = Application.get_env(:parapet, :notifiers, [])

    Enum.each(notifiers, fn {adapter, opts} ->
      dispatch(incident, adapter, opts)
    end)

    :ok
  end

  def dispatch(incident, adapter, opts) do
    # Check if Oban is loaded.
    if Code.ensure_loaded?(Oban) and Application.get_env(:parapet, :use_oban_for_notifications, true) do
      args = %{
        "incident_id" => incident.id,
        "adapter" => to_string(adapter),
        "opts" => inspect(opts)
      }
      Parapet.Notifier.ObanWorker.new(args) |> Oban.insert()
    else
      Task.start(fn ->
        adapter.deliver(incident, opts)
      end)
    end
  end
end
