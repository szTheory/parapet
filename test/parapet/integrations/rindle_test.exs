defmodule Parapet.Integrations.RindleTest do
  use ExUnit.Case, async: false

  setup do
    Parapet.Integrations.Rindle.setup()

    test_pid = self()
    handler_id = "test-parapet-journey-media-#{System.unique_integer()}"
    
    :telemetry.attach(
      handler_id,
      [:parapet, :journey, :media],
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

  test "translates rindle media event into parapet journey media event" do
    :telemetry.execute([:rindle, :media, :processed], %{duration: 100}, %{file_id: 2})
    assert_receive {:telemetry_event, [:parapet, :journey, :media], %{duration: 100}, %{file_id: 2, outcome: :success}}
    
    :telemetry.execute([:rindle, :media, :failed], %{duration: 100}, %{file_id: 2})
    assert_receive {:telemetry_event, [:parapet, :journey, :media], %{duration: 100}, %{file_id: 2, outcome: :failure}}
  end
end
