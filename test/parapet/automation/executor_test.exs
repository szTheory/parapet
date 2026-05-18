defmodule Parapet.Automation.ExecutorTest do
  use ExUnit.Case, async: false

  alias Parapet.Automation.Executor
  alias Parapet.Spine.Incident

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
    end)
    :ok
  end

  test "perform/1 executes the mitigation via Operator under system identity" do
    job = %Oban.Job{args: %{"incident_id" => "inc-1", "step_id" => "auto_step"}}
    assert :ok = Executor.perform(job)

    assert_received :mitigated
    
    assert_received {:transaction, ops}
    
    # Find the timeline_entry op in the transaction ops
    {_name, {:run, run_fun}} = Enum.find(ops, fn {name, _op} -> name == :timeline_entry end)
    
    # The run_fun is an internal Ecto function for insert with a callback.
    # In older Ecto, it might be {:insert, fun, _opts}.
    # We can just check that run_fun or the generated changeset has what we need.
    # Alternatively, we know run_fun takes (repo, changes_so_far).
    # Let's extract the changeset by calling the callback if it's an insert fun.
    
    # But wait, in Ecto, `Ecto.Multi.insert(:timeline_entry, fun)` actually adds a `{:run, ...}` that calls Repo.insert.
    # The simplest way is to mock Repo.insert to send us the changeset!
    
    assert_received {:insert, Parapet.Spine.TimelineEntry, changeset}
    
    payload = Ecto.Changeset.get_field(changeset, :payload)
    
    assert payload["actor"] == "system:automation:executor"
    assert payload["step_id"] == "auto_step"
    assert payload["result"] == ":mitigated"
  end

  test "perform/1 returns error when incident is not found" do
    job = %Oban.Job{args: %{"incident_id" => "not-found", "step_id" => "auto_step"}}
    assert {:error, :incident_not_found} = Executor.perform(job)
  end
end
