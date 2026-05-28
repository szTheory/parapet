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

  @default_lease_ms 5 * 60 * 1_000

  def claim_action(opts) do
    repo = Keyword.get(opts, :repo, Evidence.repo())
    incident_id = Keyword.fetch!(opts, :incident_id)
    action_kind = opts |> Keyword.fetch!(:action_kind) |> to_string()
    action_key = opts |> Keyword.fetch!(:action_key) |> to_string()
    idempotency_key = Keyword.fetch!(opts, :idempotency_key)
    now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:microsecond))
    lease_until = DateTime.add(now, @default_lease_ms, :millisecond) |> DateTime.truncate(:microsecond)

    attrs = %{
      incident_id: incident_id,
      action_kind: action_kind,
      action_key: action_key,
      status: "claimed",
      idempotency_key: idempotency_key,
      attempt_count: Keyword.get(opts, :attempt_count, 1),
      claimed_at: now,
      lease_until: lease_until,
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

  @doc """
  Releases a won claim after the action failed to execute.

  Transitions the claim to `"failed_retryable"` (so it no longer counts as a
  live `"claimed"` lease) and records the error. A subsequent `claim_action/1`
  for the same logical action re-grants the row via `steal_expired_claim/2`,
  letting the caller retry immediately instead of waiting out the lease window.
  Pass `status: "failed_terminal"` to mark a non-retryable failure.
  """
  def mark_failed(claim, reason, opts \\ []) do
    repo = Keyword.get(opts, :repo, Evidence.repo())
    status = Keyword.get(opts, :status, "failed_retryable")
    {kind, message} = describe_error(reason)

    update_claim_status(repo, claim, status, %{
      last_error_kind: kind,
      last_error_message: message
    })
  end

  defp describe_error({kind, detail}) when is_atom(kind),
    do: {to_string(kind), to_string_safe(detail)}

  defp describe_error(reason) when is_atom(reason), do: {to_string(reason), nil}
  defp describe_error(reason), do: {"error", to_string_safe(reason)}

  defp to_string_safe(term) when is_binary(term), do: term
  defp to_string_safe(term), do: inspect(term)

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
      case steal_expired_claim(repo, attrs) do
        {:won, claim} ->
          {:won, claim}

        nil ->
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
  end

  defp steal_expired_claim(repo, attrs) do
    now = attrs.claimed_at
    new_lease_until = DateTime.add(now, @default_lease_ms, :millisecond) |> DateTime.truncate(:microsecond)

    # Re-grant the row when the prior holder's lease expired (crashed node) OR
    # when a previous attempt was released as retryable. Resetting status to
    # "claimed" and clearing the stale error fields gives the retry a clean
    # lease while preserving the incrementing attempt_count for audit.
    steal_query =
      from(claim in ActionClaim,
        where:
          claim.incident_id == ^attrs.incident_id and
            claim.action_kind == ^attrs.action_kind and
            claim.action_key == ^attrs.action_key and
            ((claim.status == "claimed" and claim.lease_until < ^now) or
               claim.status == "failed_retryable"),
        update: [
          set: [
            status: "claimed",
            idempotency_key: ^attrs.idempotency_key,
            claimed_at: ^now,
            lease_until: ^new_lease_until,
            updated_at: ^now,
            last_error_kind: nil,
            last_error_message: nil
          ],
          inc: [attempt_count: 1]
        ],
        select: claim
      )

    {count, rows} = repo.update_all(steal_query, [])

    if count == 1 do
      {:won, rows |> List.first() |> to_claim()}
    else
      nil
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
    allowed_states = Keyword.get(opts, :allowed_states, ["open"])

    with :ok <- incident_state_gate(incident, allowed_states),
         :ok <- breaker_gate(repo, incident.id, Keyword.get(opts, :breaker_step_id)),
         :ok <- suppression_gate(incident, opts),
         :ok <- custom_gate(repo, incident, claim, opts) do
      :ok
    end
  end

  defp incident_state_gate(%Incident{state: state}, allowed_states) do
    if state in allowed_states do
      :ok
    else
      {:short_circuit, "already_#{state}"}
    end
  end

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
      :lease_until,
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
