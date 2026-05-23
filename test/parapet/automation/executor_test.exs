defmodule Parapet.Automation.ExecutorTest do
  use ExUnit.Case, async: false

  alias Parapet.Automation.Executor
  alias Parapet.Spine.{ActionClaim, Incident}

  defmodule DummyRepo do
    def get(Incident, "not-found"), do: nil

    def get(Incident, id) do
      %Incident{
        id: id,
        correlation_key: "corr_1",
        runbook_data: %{"module" => "Elixir.Parapet.Automation.ExecutorTest.MockRunbook"}
      }
    end

    def insert(changeset, _opts \\ []) do
      send(self(), {:insert, changeset.data.__struct__, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def insert!(changeset, opts \\ []) do
      {:ok, result} = insert(changeset, opts)
      result
    end

    def transaction(multi) do
      ops = Ecto.Multi.to_list(multi)
      send(self(), {:transaction, ops})

      multi
      |> Ecto.Multi.to_list()
      |> Enum.reduce_while({:ok, %{incident: %Incident{id: "inc-1"}}}, fn
        {name, {:update, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
          {:cont, {:ok, Map.put(acc, name, Ecto.Changeset.apply_changes(changeset))}}

        {name, {:insert, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
          send(self(), {name, changeset})
          {:cont, {:ok, Map.put(acc, name, Ecto.Changeset.apply_changes(changeset))}}

        {name, {:run, fun}}, {:ok, acc} ->
          # In newer Ecto, multi.insert with function becomes a :run under the hood.
          # We just run the function and if it returns a struct/changeset, we can inspect it.
          case fun.(__MODULE__, acc) do
            {:ok, value} -> 
              {:cont, {:ok, Map.put(acc, name, value)}}
            {:error, error} -> {:halt, {:error, name, error, acc}}
          end
          
        {name, other}, {:ok, acc} ->
          # Catch all for unexpected operations
          IO.puts("Unexpected operation: #{name} - #{inspect(other)}")
          {:cont, {:ok, acc}}
      end)
    end
  end

  defmodule WinningClaimService do
    def claim_action(opts) do
      send(self(), {:claim_action, opts})

      {:won,
       %ActionClaim{
         id: "claim-1",
         incident_id: opts[:incident_id],
         action_kind: opts[:action_kind],
         action_key: opts[:action_key],
         status: "claimed",
         idempotency_key: opts[:idempotency_key]
       }}
    end

    def mark_executed(claim, _opts \\ []) do
      send(self(), {:mark_executed, claim})
      %{claim | status: "executed"}
    end
  end

  defmodule ShortCircuitClaimService do
    def claim_action(opts) do
      send(self(), {:claim_action, opts})
      {:short_circuited, %ActionClaim{id: "claim-1", status: "short_circuited"}, "circuit_breaker_tripped"}
    end

    def mark_executed(_claim, _opts \\ []), do: raise("should not mark executed")
  end

  defmodule ConflictClaimService do
    def claim_action(opts) do
      send(self(), {:claim_action, opts})
      {:conflicted, %ActionClaim{id: "claim-1", status: "claimed"}}
    end

    def mark_executed(_claim, _opts \\ []), do: raise("should not mark executed")
  end

  defmodule MockRunbook do
    use Parapet.Runbook

    step(:auto_step,
      type: :mitigation,
      auto_execute: true
    )

    def execute_mitigation(:auto_step, _incident) do
      send(self(), :mitigated)
      {:ok, :mitigated}
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)

    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
      Application.delete_env(:parapet, :automation_claim_service)
      Application.delete_env(:parapet, :escalation_policy)
    end)

    :ok
  end

  test "perform/1 claims before executing and marks the winning claim executed" do
    Application.put_env(:parapet, :automation_claim_service, WinningClaimService)

    job = %Oban.Job{args: %{"incident_id" => "inc-1", "step_id" => "auto_step"}}
    assert :ok = Executor.perform(job)

    assert_received {:claim_action, claim_opts}
    assert claim_opts[:incident_id] == "inc-1"
    assert claim_opts[:action_kind] == "automation"
    assert claim_opts[:action_key] == "auto_step"
    assert claim_opts[:breaker_step_id] == "auto_step"
    assert claim_opts[:idempotency_key] == "auto_exec_inc-1_auto_step"

    assert_received :mitigated
    assert_received {:mark_executed, %ActionClaim{idempotency_key: "auto_exec_inc-1_auto_step"}}

    assert_received {:transaction, ops}

    {_name, {:run, _run_fun}} = Enum.find(ops, fn {name, _op} -> name == :timeline_entry end)

    assert_received {:insert, Parapet.Spine.TimelineEntry, changeset}
    payload = Ecto.Changeset.get_field(changeset, :payload)

    assert payload["actor"] == "system:automation:executor"
    assert payload["step_id"] == "auto_step"
    assert payload["result"] == ":mitigated"
  end

  test "perform/1 records a typed short-circuit outcome and enqueues escalation on breaker refusal" do
    Application.put_env(:parapet, :automation_claim_service, ShortCircuitClaimService)
    Application.put_env(:parapet, :escalation_policy, SuccessPolicy)

    job = %Oban.Job{args: %{"incident_id" => "inc-1", "step_id" => "auto_step"}}
    assert {:discard, "Circuit breaker tripped for step auto_step"} = Executor.perform(job)

    assert_received {:claim_action, claim_opts}
    assert claim_opts[:idempotency_key] == "auto_exec_inc-1_auto_step"

    assert_received {:insert, Parapet.Spine.TimelineEntry, changeset}
    assert Ecto.Changeset.get_field(changeset, :type) == "automation_short_circuited"

    assert Ecto.Changeset.get_field(changeset, :payload) == %{
             "step_id" => "auto_step",
             "reason" => "circuit_breaker_tripped"
           }

    assert_received {:insert, Oban.Job, job_changeset}
    assert Ecto.Changeset.get_field(job_changeset, :worker) == "Parapet.Escalation.Worker"
  end

  test "perform/1 records a typed conflict outcome when another worker already owns the claim" do
    Application.put_env(:parapet, :automation_claim_service, ConflictClaimService)

    job = %Oban.Job{args: %{"incident_id" => "inc-1", "step_id" => "auto_step"}}

    assert {:discard, "Automation claim conflicted for step auto_step"} = Executor.perform(job)

    assert_received {:claim_action, claim_opts}
    assert claim_opts[:idempotency_key] == "auto_exec_inc-1_auto_step"

    assert_received {:insert, Parapet.Spine.TimelineEntry, changeset}
    assert Ecto.Changeset.get_field(changeset, :type) == "automation_claim_conflicted"
    assert Ecto.Changeset.get_field(changeset, :payload) == %{"step_id" => "auto_step"}
    refute_received :mitigated
  end

  test "perform/1 returns error when incident is not found" do
    job = %Oban.Job{args: %{"incident_id" => "not-found", "step_id" => "auto_step"}}
    assert {:error, :incident_not_found} = Executor.perform(job)
  end
end
