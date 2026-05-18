defmodule Parapet.RunbookTest do
  use ExUnit.Case, async: true

  defmodule DummyRunbook do
    use Parapet.Runbook

    title("Test Runbook")
    description("A runbook for testing purposes.")

    step(:restart,
      label: "Restart Service",
      description: "Restarts the target service.",
      type: :mitigation
    )

    step(:notify,
      label: "Notify Team",
      description: "Ping the team.",
      type: :manual
    )

    step(:retry,
      label: "Retry Item",
      description: "Retry the background item.",
      type: :mitigation,
      kind: :capability,
      capability: :retry_async_item,
      target_kind: :async_item,
      requires_preview: true
    )

    step(:investigate,
      label: "Investigate Manually",
      description: "Look at the logs.",
      type: :manual,
      kind: :guidance,
      preview_only: true,
      guidance: "Go to Grafana..."
    )

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
      assert length(schema.steps) == 4

      [restart_step, notify_step, retry_step, investigate_step] = schema.steps

      assert restart_step.id == :restart
      assert restart_step.label == "Restart Service"
      assert restart_step.description == "Restarts the target service."
      assert restart_step.type == :mitigation
      assert restart_step.requires_preview == false
      assert restart_step.preview_only == false

      assert notify_step.id == :notify
      assert notify_step.label == "Notify Team"
      assert notify_step.description == "Ping the team."
      assert notify_step.type == :manual
      assert notify_step.requires_preview == false
      assert notify_step.preview_only == false

      assert retry_step.id == :retry
      assert retry_step.label == "Retry Item"
      assert retry_step.description == "Retry the background item."
      assert retry_step.type == :mitigation
      assert retry_step.kind == :capability
      assert retry_step.capability == :retry_async_item
      assert retry_step.target_kind == :async_item
      assert retry_step.requires_preview == true
      assert retry_step.preview_only == false

      assert investigate_step.id == :investigate
      assert investigate_step.label == "Investigate Manually"
      assert investigate_step.description == "Look at the logs."
      assert investigate_step.type == :manual
      assert investigate_step.kind == :guidance
      assert investigate_step.requires_preview == false
      assert investigate_step.preview_only == true
      assert investigate_step.guidance == "Go to Grafana..."
    end

    test "default execute_mitigation returns {:error, :not_implemented}" do
      assert {:error, :not_implemented} = DummyRunbook.execute_mitigation(:notify, %{})
    end

    test "overridden execute_mitigation returns implemented value" do
      assert {:ok, %{restarted: true}} = DummyRunbook.execute_mitigation(:restart, %{})
    end
  end
end
