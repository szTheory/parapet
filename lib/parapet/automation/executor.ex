if Code.ensure_loaded?(Oban.Worker) do
  defmodule Parapet.Automation.Executor do
    @moduledoc """
    Oban worker for executing automated runbook mitigations.
    Safely delegates back to the Operator API under a system identity.

    > #### Experimental {: .warning}
    >
    > This module is **experimental** in v1.x. Its API may change in a minor release with a
    > single-version notice in CHANGELOG.md. See
    > [Stability & Deprecation Policy](stability.html) for details.
    """
    use Oban.Worker,
      queue: :default,
      unique: [period: 3600, keys: [:incident_id, :step_id]]

    alias Parapet.Automation.ClaimService
    alias Parapet.Evidence
    alias Parapet.Spine.Incident
    alias Parapet.Operator
    alias Parapet.Operator.ActionPayload

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"incident_id" => incident_id, "step_id" => step_id}}) do
      case Evidence.repo().get(Incident, incident_id) do
        %Incident{} = incident ->
          idempotency_key = "auto_exec_#{incident_id}_#{step_id}"

          case claim_service().claim_action(
                 incident_id: incident_id,
                 action_kind: "automation",
                 action_key: step_id,
                 breaker_step_id: step_id,
                 idempotency_key: idempotency_key
               ) do
            {:won, claim} ->
              execute_claimed_step(incident, step_id, idempotency_key, claim)

            {:short_circuited, _claim, reason} ->
              record_short_circuit(incident_id, step_id, reason)

            {:conflicted, _claim} ->
              record_claim_conflict(incident_id, step_id)

            {:error, reason} ->
              {:error, reason}
          end

        nil ->
          {:error, :incident_not_found}
      end
    end

    defp execute_claimed_step(incident, step_id, idempotency_key, claim) do
      payload = %ActionPayload{
        actor: "system:automation:executor",
        action_type: :execute_mitigation,
        reason: "Automated runbook mitigation triggered via alert.",
        correlation_id: incident.correlation_key,
        idempotency_key: idempotency_key
      }

      case Operator.execute_runbook_step(incident, step_id, payload) do
        {:ok, _result} ->
          claim_service().mark_executed(claim)
          :ok

        {:error, reason} ->
          {:error, reason}
      end
    end

    defp record_short_circuit(incident_id, step_id, reason) do
      Evidence.append_timeline(incident_id, %{
        type: "automation_short_circuited",
        payload: %{"step_id" => step_id, "reason" => reason}
      })

      if reason == "circuit_breaker_tripped" do
        maybe_enqueue_escalation(incident_id)
        {:discard, "Circuit breaker tripped for step #{step_id}"}
      else
        {:discard, "Automation short-circuited for step #{step_id}: #{reason}"}
      end
    end

    defp record_claim_conflict(incident_id, step_id) do
      Evidence.append_timeline(incident_id, %{
        type: "automation_claim_conflicted",
        payload: %{"step_id" => step_id}
      })

      {:discard, "Automation claim conflicted for step #{step_id}"}
    end

    defp maybe_enqueue_escalation(incident_id) do
      if Code.ensure_loaded?(Oban) and Application.get_env(:parapet, :escalation_policy) do
        %{incident_id: incident_id}
        |> Parapet.Escalation.Worker.new()
        |> Evidence.repo().insert!()
      end
    end

    defp claim_service do
      Application.get_env(:parapet, :automation_claim_service, ClaimService)
    end
  end
end
