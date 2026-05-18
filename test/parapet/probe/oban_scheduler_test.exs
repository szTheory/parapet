defmodule Parapet.Probe.ObanSchedulerTest do
  use ExUnit.Case, async: true

  alias Parapet.Probe.ObanScheduler

  defmodule TestProbe do
    use Parapet.Probe

    @impl true
    def run do
      send(:test_process_oban, :probe_executed)
      if Process.get(:test_fail), do: {:error, :fail}, else: :ok
    end
  end

  defmodule NotAProbe do
    def something_else, do: :ok
  end

  test "worker defines max_attempts: 1" do
    changeset = ObanScheduler.new(%{"probe" => "something"})
    assert Ecto.Changeset.get_change(changeset, :max_attempts) == 1
  end

  test "perform/1 invokes the probe module" do
    Process.register(self(), :test_process_oban)

    job = %Oban.Job{args: %{"probe" => to_string(TestProbe)}}

    assert :ok == ObanScheduler.perform(job)
    assert_receive :probe_executed
  end

  test "perform/1 returns error if module is not a probe" do
    job = %Oban.Job{args: %{"probe" => to_string(NotAProbe)}}

    assert {:error, :invalid_probe} == ObanScheduler.perform(job)
  end

  test "perform/1 returns error if module does not exist" do
    job = %Oban.Job{args: %{"probe" => "Elixir.NonExistentProbe"}}

    assert {:error, :invalid_probe} == ObanScheduler.perform(job)
  end
end
