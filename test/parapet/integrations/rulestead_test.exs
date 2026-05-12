defmodule Parapet.Integrations.RulesteadTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      :telemetry.detach("parapet-rulestead-flag")
    end)

    :ok
  end

  describe "setup/0" do
    test "attaches telemetry and registers capability" do
      Parapet.Integrations.Rulestead.setup()

      handlers = :telemetry.list_handlers([:rulestead, :flag, :changed])
      assert Enum.any?(handlers, fn handler -> handler.id == "parapet-rulestead-flag" end)

      capabilities = Parapet.Capabilities.capabilities(:mitigation)

      assert Enum.any?(capabilities, fn cap ->
               cap.id == :rulestead and cap.name == "toggle_flag" and
                 cap.schema.name == "Toggle Feature Flag"
             end)
    end
  end

  describe "handle_event/4" do
    setup do
      test_pid = self()
      handler_id = "test-parapet-journey-flag"

      :telemetry.attach(
        handler_id,
        [:parapet, :mitigation, :rulestead, :flag, :changed],
        fn name, measurements, metadata, _config ->
          send(test_pid, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn ->
        :telemetry.detach(handler_id)
      end)

      :ok
    end

    test "translates rulestead flag change event safely without PII" do
      Parapet.Integrations.Rulestead.setup()

      :telemetry.execute(
        [:rulestead, :flag, :changed],
        %{duration: 100},
        %{flag_name: "new_ui", state: true, user_id: 123}
      )

      assert_receive {:telemetry_event, [:parapet, :mitigation, :rulestead, :flag, :changed],
                      measurements, metadata}

      assert measurements.duration == 100
      assert metadata.flag_name == "new_ui"
      assert metadata.state == true
      refute Map.has_key?(metadata, :user_id)
    end
  end
end
