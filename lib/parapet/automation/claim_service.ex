defmodule Parapet.Automation.ClaimService do
  @moduledoc """
  Transaction seam for durable logical-action claims under contention.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  import Ecto.Query

  alias Parapet.Automation.CircuitBreaker
  alias Parapet.Evidence
  alias Parapet.Spine.{ActionClaim, Incident}

  def claim_action(opts) do
    repo = Keyword.get(opts, :repo, Evidence.repo())
    incident_id = Keyword.fetch!(opts, :incident_id)
    action_kind = opts |> Keyword.fetch!(:action_kind) |> to_string()
    action_key = opts |> Keyword.fetch!(:action_key) |> to_string()
    idempotency_key = Keyword.fetch!(opts, :idempotency_key)
    now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:microsecond))

    attrs = %{
      incident_id: incident_id,
      action_kind: action_kind,
      action_key: action_key,
      status: "claimed",
      idempotency_key: idempotency_key,
      attempt_count: Keyword.get(opts, :attempt_count, 1),
      claimed_at: now,
      inserted_at: now,
      updated_at: now
    }

    case repo.transaction(fn ->
           case acquire_claim(repo, attrs) do
             {:won, claim} ->
               incident =
                 lock_incident(repo, incident_id, Keyword.get(opts, :lock_incident?, true))

               case run_gates(repo, incident, claim, opts) do
                 :ok ->
                   {:won, claim}

                 {:short_circuit, reason} ->
                   claim =
                     update_claim_status(repo, claim, "short_circuited", %{
                       short_circuit_reason: reason
                     })

                   {:short_circuited, claim, reason}
               end

             {:conflicted, claim} ->
               {:conflicted, claim}
           end
         end) do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  def mark_executed(claim, opts \\ []) do
    repo = Keyword.get(opts, :repo, Evidence.repo())

    finished_at =
      Keyword.get(opts, :finished_at, DateTime.utc_now() |> DateTime.truncate(:microsecond))

    update_claim_status(repo, claim, "executed", %{finished_at: finished_at})
  end

  defp acquire_claim(repo, attrs) do
    {count, rows} =
      repo.insert_all(ActionClaim, [Map.put(attrs, :error_metadata, %{})],
        on_conflict: :nothing,
        conflict_target: [:incident_id, :action_kind, :action_key],
        returning: returning_fields()
      )

    if count == 1 do
      {:won, rows |> returned_claim() |> to_claim()}
    else
      claim =
        repo.one!(
          from(claim in ActionClaim,
            where:
              claim.incident_id == ^attrs.incident_id and
                claim.action_kind == ^attrs.action_kind and
                claim.action_key == ^attrs.action_key
          )
        )

      {:conflicted, claim}
    end
  end

  defp lock_incident(repo, incident_id, true) do
    repo.one!(
      from(incident in Incident,
        where: incident.id == ^incident_id,
        lock: "FOR UPDATE"
      )
    )
  end

  defp lock_incident(repo, incident_id, false), do: repo.get!(Incident, incident_id)

  defp run_gates(repo, incident, claim, opts) do
    with :ok <- incident_state_gate(incident),
         :ok <- breaker_gate(repo, incident.id, Keyword.get(opts, :breaker_step_id)),
         :ok <- suppression_gate(incident, opts),
         :ok <- custom_gate(repo, incident, claim, opts) do
      :ok
    end
  end

  defp incident_state_gate(%Incident{state: "open"}), do: :ok
  defp incident_state_gate(%Incident{state: state}), do: {:short_circuit, "already_#{state}"}

  defp breaker_gate(_repo, _incident_id, nil), do: :ok

  defp breaker_gate(repo, incident_id, step_id) do
    case CircuitBreaker.gate(repo, incident_id, step_id) do
      :ok -> :ok
      {:short_circuit, reason} -> {:short_circuit, reason}
    end
  end

  defp suppression_gate(incident, opts) do
    case Keyword.get(opts, :suppression_check, fn _incident -> nil end).(incident) do
      :ok -> :ok
      nil -> :ok
      false -> :ok
      {:short_circuit, reason} -> {:short_circuit, to_string(reason)}
      reason -> {:short_circuit, to_string(reason)}
    end
  end

  defp custom_gate(repo, incident, claim, opts) do
    case Keyword.get(opts, :gate, fn _repo, _incident, _claim -> :ok end).(repo, incident, claim) do
      :ok -> :ok
      {:short_circuit, reason} -> {:short_circuit, to_string(reason)}
      false -> :ok
      nil -> :ok
      other -> {:short_circuit, to_string(other)}
    end
  end

  defp update_claim_status(repo, claim, status, attrs) do
    claim
    |> ActionClaim.changeset(Map.put(attrs, :status, status))
    |> repo.update!()
  end

  defp to_claim(%ActionClaim{} = claim), do: claim
  defp to_claim(attrs), do: struct(ActionClaim, attrs)

  defp returned_claim([claim | _rest]), do: claim
  defp returned_claim(claim), do: claim

  defp returning_fields do
    [
      :id,
      :incident_id,
      :action_kind,
      :action_key,
      :status,
      :idempotency_key,
      :attempt_count,
      :claimed_at,
      :finished_at,
      :short_circuit_reason,
      :last_error_kind,
      :last_error_message,
      :error_metadata,
      :inserted_at,
      :updated_at
    ]
  end
end
