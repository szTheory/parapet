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
        policy_config = Application.get_env(:parapet, :escalation_policy)

        if policy_config do
          {policy_module, opts} =
            case policy_config do
              {mod, config_opts} -> {mod, config_opts}
              mod when is_atom(mod) -> {mod, []}
            end

          execute_policy(incident, policy_module, opts)
        else
          {:discard, "No escalation policy configured"}
        end
    end
  end

  defp execute_policy(incident, policy_module, opts) do
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
      payload: %{
        policy: inspect(policy_module),
        status: status,
        details: details
      }
    })

    if status == "error" do
      {:error, details}
    else
      :ok
    end
  end
end
