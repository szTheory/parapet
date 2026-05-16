defmodule Parapet.ProbeTest do
  use ExUnit.Case, async: true

  defmodule SuccessProbe do
    use Parapet.Probe

    @impl true
    def run, do: :ok
  end

  defmodule ErrorProbe do
    use Parapet.Probe

    @impl true
    def run, do: {:error, :timeout}
  end

  test "execute/0 wraps run/0 in a telemetry span for success" do
    parent = self()
    ref = make_ref()
    
    :telemetry.attach("probe-success-test", [:parapet, :probe, :run, :stop], fn event, measurements, metadata, _config -> 
      send(parent, {ref, event, measurements, metadata})
    end, nil)

    assert :ok = SuccessProbe.execute()

    assert_receive {^ref, [:parapet, :probe, :run, :stop], %{duration: _}, metadata}
    assert metadata.probe == "Parapet.ProbeTest.SuccessProbe"
    assert metadata.status == "success"
    
    :telemetry.detach("probe-success-test")
  end

  test "execute/0 wraps run/0 in a telemetry span for error" do
    parent = self()
    ref = make_ref()
    
    :telemetry.attach("probe-error-test", [:parapet, :probe, :run, :stop], fn event, measurements, metadata, _config -> 
      send(parent, {ref, event, measurements, metadata})
    end, nil)

    assert {:error, :timeout} = ErrorProbe.execute()

    assert_receive {^ref, [:parapet, :probe, :run, :stop], %{duration: _}, metadata}
    assert metadata.probe == "Parapet.ProbeTest.ErrorProbe"
    assert metadata.status == "error"
    
    :telemetry.detach("probe-error-test")
  end
end
