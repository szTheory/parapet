defmodule Parapet.DeployTest do
  use ExUnit.Case, async: false

  setup do
    test_pid = self()
    handler_id = "test-parapet-deploy-mark"

    :telemetry.attach(
      handler_id,
      [:parapet, :deploy, :mark],
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

  describe "mark/1" do
    test "emits deploy telemetry event with monotonic time and metadata" do
      Parapet.Deploy.mark(version: "1.2.3")

      assert_receive {:telemetry_event, [:parapet, :deploy, :mark], measurements, metadata}

      assert is_integer(measurements.system_time)
      assert metadata.version == "1.2.3"
    end
  end
end
