defmodule Parapet.Integrations.AccrueTest do
  use ExUnit.Case, async: false

  setup do
    Parapet.Integrations.Accrue.setup()

    test_pid = self()
    handler_id = "test-parapet-journey-billing-#{System.unique_integer()}"
    
    :telemetry.attach(
      handler_id,
      [:parapet, :journey, :billing],
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

  test "translates accrue billing event into parapet journey billing event" do
    :telemetry.execute([:accrue, :billing, :processed], %{amount: 500}, %{account_id: 1})
    assert_receive {:telemetry_event, [:parapet, :journey, :billing], %{amount: 500}, %{account_id: 1, outcome: :success}}
    
    :telemetry.execute([:accrue, :billing, :failed], %{amount: 500}, %{account_id: 1})
    assert_receive {:telemetry_event, [:parapet, :journey, :billing], %{amount: 500}, %{account_id: 1, outcome: :failure}}
  end
end
