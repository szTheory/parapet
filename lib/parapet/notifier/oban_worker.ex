if Code.ensure_loaded?(Oban.Worker) do
  defmodule Parapet.Notifier.ObanWorker do
    @moduledoc """
    Oban worker for durable asynchronous dispatch of notifications.
    """
    use Oban.Worker, queue: :default

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"incident_id" => incident_id, "adapter" => adapter_str}}) do
      adapter = String.to_existing_atom(adapter_str)

      # We must fetch the incident to pass it to the adapter.
      incident = Parapet.Evidence.repo().get(Parapet.Spine.Incident, incident_id)

      if incident do
        # Fetch opts from config for this adapter
        opts =
          Application.get_env(:parapet, :notifiers, [])
          |> Enum.find_value([], fn
            {^adapter, o} -> o
            _ -> nil
          end)

        Parapet.Notifier.deliver_and_audit(incident, adapter, opts)
      else
        # If incident is not found, we shouldn't retry.
        {:discard, "Incident #{incident_id} not found."}
      end
    end
  end
end
