defmodule Parapet.Escalation.Worker do
  @moduledoc """
  Oban worker for durable asynchronous dispatch of escalations.
  """
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"incident_id" => incident_id}}) do
    incident = Parapet.Evidence.repo().get(Parapet.Spine.Incident, incident_id)

    case incident do
      nil ->
        {:discard, "Incident #{incident_id} not found"}

      %{state: state} when state in ["investigating", "resolved"] ->
        Parapet.Evidence.append_timeline(incident_id, %{
          type: "escalation_short_circuited",
          payload: %{"reason" => "already_#{state}"}
        })

        {:discard, "Short-circuited (already #{state})"}

      %{state: "open"} ->
        escalation_state = escalation_command_state(incident)

        if suppression_active?(escalation_state) do
          Parapet.Evidence.append_timeline(incident_id, %{
            type: "escalation_short_circuited",
            payload: %{
              "reason" => "suppressed",
              "suppressed_until" => escalation_state["suppressed_until"],
              "suppressed_by" => escalation_state["suppressed_by"],
              "suppression_reason" => escalation_state["suppression_reason"]
            }
          })

          {:discard, "Short-circuited (suppressed)"}
        else
          policy_config = Application.get_env(:parapet, :escalation_policy)

          if policy_config do
            {policy_module, opts} =
              case policy_config do
                {mod, config_opts} -> {mod, config_opts}
                mod when is_atom(mod) -> {mod, []}
              end

            execute_policy(incident, escalation_state, policy_module, opts)
          else
            {:discard, "No escalation policy configured"}
          end
        end
    end
  end

  defp execute_policy(incident, escalation_state, policy_module, opts) do
    {status, details} =
      try do
        case policy_module.escalate(incident, opts) do
          {:ok, result} -> {"success", inspect(result)}
          {:error, reason} -> {"error", inspect(reason)}
          other -> {"error", inspect(other)}
        end
      rescue
        e -> {"error", inspect(e)}
      catch
        type, value -> {"error", "#{type}: #{inspect(value)}"}
      end

    Parapet.Evidence.append_timeline(incident.id, %{
      type: "escalation_executed",
      payload: execution_payload(escalation_state, policy_module, status, details)
    })

    if status == "error" do
      {:error, details}
    else
      :ok
    end
  end

  defp execution_payload(escalation_state, policy_module, status, details) do
    payload = %{
      "policy" => inspect(policy_module),
      "status" => status,
      "details" => details,
      "mode" => escalation_mode(escalation_state)
    }

    if payload["mode"] == "manual" do
      payload
      |> Map.put("triggered_by", escalation_state["triggered_by"])
      |> Map.put("trigger_reason", escalation_state["trigger_reason"])
    else
      payload
    end
  end

  defp escalation_mode(%{"pending_trigger" => true}), do: "manual"
  defp escalation_mode(_state), do: "scheduled"

  defp escalation_command_state(%{runbook_data: runbook_data}) when is_map(runbook_data) do
    case Map.get(runbook_data, "escalation") || Map.get(runbook_data, :escalation) do
      state when is_map(state) -> Map.new(state, fn {key, value} -> {to_string(key), value} end)
      _ -> %{}
    end
  end

  defp escalation_command_state(_incident), do: %{}

  defp suppression_active?(%{"suppressed_until" => %DateTime{} = suppressed_until}) do
    DateTime.compare(suppressed_until, DateTime.utc_now()) == :gt
  end

  defp suppression_active?(_state), do: false
end
