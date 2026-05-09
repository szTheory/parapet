defmodule Parapet.Internal.SafeHandlerTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  alias Parapet.Internal.SafeHandler

  defmodule CrashingHandler do
    def handle(_event, _measurements, _metadata, _config) do
      raise RuntimeError, "Intentional crash for testing"
    end
  end

  defmodule WorkingHandler do
    def handle(_event, _measurements, _metadata, _config) do
      # Send a message to the test process so we know it executed
      send(self(), :handler_executed)
    end
  end

  setup do
    # Ensure telemetry is clean before each test
    handler_id = "test-handler-#{System.unique_integer()}"
    event_name = [:parapet, :test, :event]
    
    on_exit(fn ->
      :telemetry.detach(handler_id)
    end)
    
    %{handler_id: handler_id, event_name: event_name}
  end

  describe "attach/5" do
    test "successfully attaches and executes handler", %{handler_id: handler_id, event_name: event_name} do
      assert :ok = SafeHandler.attach(handler_id, event_name, WorkingHandler, :handle)
      
      :telemetry.execute(event_name, %{count: 1}, %{})
      
      assert_receive :handler_executed
    end

    test "rescues handler exceptions and logs them", %{handler_id: handler_id, event_name: event_name} do
      assert :ok = SafeHandler.attach(handler_id, event_name, CrashingHandler, :handle)
      
      log = capture_log(fn ->
        # The telemetry execution should NOT raise an exception to the caller
        :telemetry.execute(event_name, %{count: 1}, %{})
      end)
      
      assert log =~ "Parapet telemetry handler exception"
      assert log =~ "Intentional crash for testing"
      # Stacktrace might vary in format but should be included
      assert log =~ "Stacktrace:"
    end
  end
end
