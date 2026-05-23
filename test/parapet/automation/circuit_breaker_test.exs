defmodule Parapet.Automation.CircuitBreakerTest do
  use ExUnit.Case, async: false

  alias Parapet.Automation.CircuitBreaker

  defmodule DummyRepo do
    def aggregate(_query, :count, :id) do
      Process.get(:mock_aggregate_count, 0)
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    Application.put_env(:parapet, :automation, max_executions: 3, within: 3600)

    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
      Application.delete_env(:parapet, :automation)
    end)

    :ok
  end

  describe "allow?/2" do
    test "returns true when ToolAudit executions are below threshold" do
      Process.put(:mock_aggregate_count, 2)
      assert CircuitBreaker.allow?("incident_1", "step_1") == true
    end

    test "returns false when ToolAudit executions reach threshold within the time window" do
      Process.put(:mock_aggregate_count, 3)
      assert CircuitBreaker.allow?("incident_1", "step_1") == false
    end

    test "returns false when ToolAudit executions exceed threshold" do
      Process.put(:mock_aggregate_count, 5)
      assert CircuitBreaker.allow?("incident_1", "step_1") == false
    end
  end
end
