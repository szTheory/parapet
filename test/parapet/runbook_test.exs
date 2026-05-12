defmodule Parapet.RunbookTest do
  use ExUnit.Case, async: true

  defmodule DummyRunbook do
    use Parapet.Runbook

    title "Test Runbook"
    description "A runbook for testing purposes."

    step :restart,
      label: "Restart Service",
      description: "Restarts the target service.",
      type: :mitigation

    step :notify,
      label: "Notify Team",
      description: "Ping the team.",
      type: :manual

    def execute_mitigation(:restart, _incident) do
      {:ok, %{restarted: true}}
    end

    def execute_mitigation(step, incident) do
      super(step, incident)
    end
  end

  describe "runbook DSL" do
    test "generates a static schema map via __runbook_schema__()" do
      schema = DummyRunbook.__runbook_schema__()

      assert schema.module == "Elixir.Parapet.RunbookTest.DummyRunbook"
      assert schema.title == "Test Runbook"
      assert schema.description == "A runbook for testing purposes."
      assert length(schema.steps) == 2

      [restart_step, notify_step] = schema.steps

      assert restart_step.id == :restart
      assert restart_step.label == "Restart Service"
      assert restart_step.description == "Restarts the target service."
      assert restart_step.type == :mitigation

      assert notify_step.id == :notify
      assert notify_step.label == "Notify Team"
      assert notify_step.description == "Ping the team."
      assert notify_step.type == :manual
    end

    test "default execute_mitigation returns {:error, :not_implemented}" do
      assert {:error, :not_implemented} = DummyRunbook.execute_mitigation(:notify, %{})
    end

    test "overridden execute_mitigation returns implemented value" do
      assert {:ok, %{restarted: true}} = DummyRunbook.execute_mitigation(:restart, %{})
    end
  end
end
