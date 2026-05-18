defmodule Parapet.Automation.Executor do
  @moduledoc """
  Oban worker for executing automated runbook mitigations.
  Safely delegates back to the Operator API under a system identity.
  """
  use Oban.Worker,
    queue: :default,
    unique: [period: 3600, keys: [:incident_id, :step_id]]

  alias Parapet.Evidence
  alias Parapet.Spine.Incident
  alias Parapet.Operator
  alias Parapet.Operator.ActionPayload

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"incident_id" => incident_id, "step_id" => step_id}}) do
    case Evidence.repo().get(Incident, incident_id) do
      %Incident{} = incident ->
        payload = %ActionPayload{
          actor: "system:automation:executor",
          action_type: :execute_mitigation,
          reason: "Automated runbook mitigation triggered via alert.",
          correlation_id: incident.correlation_key,
          idempotency_key: "auto_exec_#{incident_id}_#{step_id}"
        }

        # Step ID is stored as a string in Oban args, Operator API accepts it
        case Operator.execute_runbook_step(incident, step_id, payload) do
          {:ok, _result} -> :ok
          {:error, reason} -> {:error, reason}
        end

      nil ->
        {:error, :incident_not_found}
    end
  end
end
