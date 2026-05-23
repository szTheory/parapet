if Code.ensure_loaded?(Oban.Worker) do
  defmodule Parapet.Escalation.Worker do
    @moduledoc """
    Oban worker for durable asynchronous dispatch of escalations.
    """
    use Oban.Worker,
      queue: :default,
      unique: [period: 3600, keys: [:incident_id]]

    alias Ecto.Multi
    alias Parapet.Automation.ClaimService
    alias Parapet.Evidence
    alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry}

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"incident_id" => incident_id}} = job) do
      case Evidence.repo().get(Incident, incident_id) do
        nil ->
          {:discard, "Incident #{incident_id} not found"}

        %Incident{} = incident ->
          case escalation_policy() do
            nil ->
              {:discard, "No escalation policy configured"}

            {policy_module, opts} ->
              escalation_state = escalation_command_state(incident)
              action_key = escalation_action_key(escalation_state)
              idempotency_key = escalation_idempotency_key(incident_id, action_key)

              case ClaimService.claim_action(
                     incident_id: incident_id,
                     action_kind: "escalation",
                     action_key: action_key,
                     idempotency_key: idempotency_key,
                     suppression_check: &suppression_gate/1
                   ) do
                {:won, claim} ->
                  execute_claim(incident_id, escalation_state, claim, policy_module, opts, job)

                {:short_circuited, claim, reason} ->
                  persist_short_circuit(incident_id, escalation_state, claim, reason)

                {:conflicted, claim} ->
                  resolve_conflict(
                    incident_id,
                    escalation_state,
                    claim,
                    idempotency_key,
                    policy_module,
                    opts,
                    job
                  )

                {:error, reason} ->
                  {:error, reason}
              end
          end
      end
    end

    defp execute_claim(
           incident_id,
           initial_escalation_state,
           %ActionClaim{} = claim,
           policy_module,
           opts,
           %Oban.Job{} = job
         ) do
      incident = Evidence.repo().get!(Incident, incident_id)
      escalation_state = escalation_command_state(incident)

      policy_opts =
        Keyword.merge(opts,
          idempotency_key: claim.idempotency_key,
          escalation_claim_id: claim.id,
          escalation_action_key: claim.action_key
        )

      case invoke_policy(policy_module, incident, policy_opts) do
        {:ok, result} ->
          persist_execution_outcome(
            incident,
            claim,
            clear_pending_trigger(escalation_state),
            %{
              type: "escalation_executed",
              payload:
                execution_payload(
                  escalation_state,
                  claim,
                  policy_module,
                  "success",
                  inspect(result)
                )
            }
          )

          :ok

        {:error, kind, details} ->
          if terminal_attempt?(job) do
            persist_failure_outcome(
              incident,
              claim,
              clear_pending_trigger(escalation_state),
              policy_module,
              kind,
              details,
              "failed_terminal",
              "escalation_failed_terminal"
            )

            {:discard, "Terminal escalation failure: #{details}"}
          else
            persist_failure_outcome(
              incident,
              claim,
              initial_escalation_state,
              policy_module,
              kind,
              details,
              "failed_retryable",
              "escalation_failed_retryable"
            )

            {:error, details}
          end
      end
    end

    defp resolve_conflict(
           incident_id,
           escalation_state,
           %ActionClaim{} = claim,
           expected_idempotency_key,
           policy_module,
           opts,
           %Oban.Job{} = job
         ) do
      cond do
        resumable_claim?(claim, expected_idempotency_key, job) ->
          execute_claim(incident_id, escalation_state, claim, policy_module, opts, job)

        claim.status == "executed" ->
          {:discard, "Escalation already executed"}

        claim.status == "short_circuited" ->
          {:discard, "Escalation already short-circuited (#{claim.short_circuit_reason})"}

        claim.status == "failed_terminal" ->
          {:discard, "Escalation already failed terminal"}

        true ->
          persist_claim_conflict(incident_id, claim)
          {:discard, "Escalation claim conflicted"}
      end
    end

    defp invoke_policy(policy_module, incident, opts) do
      try do
        case policy_module.escalate(incident, opts) do
          {:ok, result} -> {:ok, result}
          {:error, reason} -> {:error, "policy_error", inspect(reason)}
          other -> {:error, "policy_error", inspect(other)}
        end
      rescue
        error -> {:error, "exception", Exception.message(error)}
      catch
        type, value -> {:error, to_string(type), inspect(value)}
      end
    end

    defp persist_short_circuit(incident_id, escalation_state, claim, reason) do
      incident = Evidence.repo().get!(Incident, incident_id)

      payload =
        %{"reason" => reason}
        |> maybe_put_suppression_details(escalation_state, reason)
        |> Map.put("idempotency_key", claim.idempotency_key)
        |> Map.put("action_key", claim.action_key)

      persist_execution_outcome(
        incident,
        claim,
        clear_pending_trigger(escalation_state),
        %{type: "escalation_short_circuited", payload: payload}
      )

      {:discard, short_circuit_message(reason)}
    end

    defp persist_claim_conflict(incident_id, claim) do
      Evidence.append_timeline(incident_id, %{
        type: "escalation_claim_conflicted",
        payload: %{
          "action_key" => claim.action_key,
          "idempotency_key" => claim.idempotency_key,
          "claim_status" => claim.status
        }
      })

      :ok
    end

    defp persist_failure_outcome(
           incident,
           claim,
           escalation_state,
           policy_module,
           error_kind,
           details,
           claim_status,
           timeline_type
         ) do
      persist_execution_outcome(
        incident,
        claim,
        escalation_state,
        %{
          type: timeline_type,
          payload:
            execution_payload(escalation_state, claim, policy_module, "error", details)
            |> Map.put("error_kind", error_kind)
        },
        status: claim_status,
        claim_attrs: %{
          last_error_kind: error_kind,
          last_error_message: details,
          error_metadata: %{"timeline_type" => timeline_type}
        }
      )
    end

    defp execution_payload(escalation_state, claim, policy_module, status, details) do
      payload = %{
        "policy" => inspect(policy_module),
        "status" => status,
        "details" => details,
        "mode" => escalation_mode(escalation_state),
        "idempotency_key" => claim.idempotency_key,
        "action_key" => claim.action_key
      }

      if payload["mode"] == "manual" do
        payload
        |> Map.put("triggered_by", escalation_state["triggered_by"])
        |> Map.put("trigger_reason", escalation_state["trigger_reason"])
      else
        payload
      end
    end

    defp escalation_policy do
      case Application.get_env(:parapet, :escalation_policy) do
        {mod, opts} -> {mod, opts}
        mod when is_atom(mod) -> {mod, []}
        _ -> nil
      end
    end

    defp escalation_mode(%{"pending_trigger" => true}), do: "manual"
    defp escalation_mode(_state), do: "scheduled"

    defp escalation_action_key(escalation_state) do
      mode = escalation_mode(escalation_state)

      suffix =
        cond do
          mode == "manual" and is_binary(Map.get(escalation_state, "trigger_requested_at")) ->
            escalation_state["trigger_requested_at"]

          mode == "manual" and
              match?(%DateTime{}, Map.get(escalation_state, "trigger_requested_at")) ->
            escalation_state["trigger_requested_at"] |> DateTime.to_iso8601()

          is_binary(Map.get(escalation_state, "current_step_id")) ->
            escalation_state["current_step_id"]

          is_binary(Map.get(escalation_state, "next_step_id")) ->
            escalation_state["next_step_id"]

          is_binary(Map.get(escalation_state, "active_step")) ->
            escalation_state["active_step"]

          match?(%DateTime{}, Map.get(escalation_state, "next_escalation_at")) ->
            escalation_state["next_escalation_at"] |> DateTime.to_iso8601()

          true ->
            "default"
        end

      "#{mode}:#{suffix}"
    end

    defp escalation_idempotency_key(incident_id, action_key) do
      "escalation_#{incident_id}_#{action_key}"
    end

    defp escalation_command_state(%{runbook_data: runbook_data}) when is_map(runbook_data) do
      case Map.get(runbook_data, "escalation") || Map.get(runbook_data, :escalation) do
        state when is_map(state) -> Map.new(state, fn {key, value} -> {to_string(key), value} end)
        _ -> %{}
      end
    end

    defp escalation_command_state(_incident), do: %{}

    defp suppression_gate(%Incident{} = incident) do
      escalation_state = escalation_command_state(incident)

      if suppression_active?(escalation_state) do
        {:short_circuit, "suppressed"}
      else
        nil
      end
    end

    defp suppression_active?(%{"suppressed_until" => %DateTime{} = suppressed_until}) do
      DateTime.compare(suppressed_until, DateTime.utc_now()) == :gt
    end

    defp suppression_active?(_state), do: false

    defp clear_pending_trigger(escalation_state) do
      escalation_state
      |> Map.delete("pending_trigger")
      |> Map.delete("triggered_by")
      |> Map.delete("trigger_reason")
      |> Map.delete("trigger_requested_at")
    end

    defp maybe_put_suppression_details(payload, escalation_state, "suppressed") do
      payload
      |> Map.put("suppressed_until", escalation_state["suppressed_until"])
      |> Map.put("suppressed_by", escalation_state["suppressed_by"])
      |> Map.put("suppression_reason", escalation_state["suppression_reason"])
    end

    defp maybe_put_suppression_details(payload, _escalation_state, _reason), do: payload

    defp persist_execution_outcome(
           incident,
           claim,
           escalation_state,
           timeline_attrs,
           opts \\ []
         ) do
      repo = Evidence.repo()
      claim_status = Keyword.get(opts, :status, "executed")

      updated_runbook_data =
        incident.runbook_data
        |> normalize_runbook_data()
        |> Map.put("escalation", escalation_state)

      incident_changeset =
        Ecto.Changeset.change(incident, %{runbook_data: updated_runbook_data})

      claim_attrs =
        opts
        |> Keyword.get(:claim_attrs, %{})
        |> Map.put(:status, claim_status)
        |> Map.put(:finished_at, DateTime.utc_now() |> DateTime.truncate(:microsecond))

      claim_changeset = Parapet.Spine.ActionClaim.changeset(claim, claim_attrs)

      multi =
        Multi.new()
        |> Multi.update(:claim, claim_changeset)
        |> Multi.update(:incident, incident_changeset)
        |> Multi.insert(:timeline_entry, fn %{incident: updated_incident} ->
          %TimelineEntry{}
          |> TimelineEntry.changeset(Map.put(timeline_attrs, :incident_id, updated_incident.id))
        end)

      case repo.transaction(multi) do
        {:ok, _result} -> :ok
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end

    defp resumable_claim?(claim, expected_idempotency_key, %Oban.Job{} = job) do
      retry_attempt?(job) and claim.idempotency_key == expected_idempotency_key and
        claim.status in ["claimed", "failed_retryable"]
    end

    defp retry_attempt?(%Oban.Job{attempt: attempt}) when is_integer(attempt), do: attempt > 1
    defp retry_attempt?(_job), do: false

    defp terminal_attempt?(%Oban.Job{attempt: attempt, max_attempts: max_attempts})
         when is_integer(attempt) and is_integer(max_attempts) do
      attempt >= max_attempts
    end

    defp terminal_attempt?(_job), do: false

    defp short_circuit_message("suppressed"), do: "Short-circuited (suppressed)"

    defp short_circuit_message("already_investigating"),
      do: "Short-circuited (already investigating)"

    defp short_circuit_message("already_resolved"), do: "Short-circuited (already resolved)"
    defp short_circuit_message(reason), do: "Short-circuited (#{reason})"

    defp normalize_runbook_data(runbook_data) when is_map(runbook_data) do
      Map.new(runbook_data, fn {key, value} -> {to_string(key), value} end)
    end

    defp normalize_runbook_data(_runbook_data), do: %{}
  end
end
