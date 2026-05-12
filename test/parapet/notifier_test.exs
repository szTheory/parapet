defmodule Parapet.NotifierTest do
  use ExUnit.Case, async: false

  defmodule DummyAdapter do
    @behaviour Parapet.Notifier
    
    @impl true
    def deliver(incident, opts) do
      send(opts[:test_pid], {:delivered, incident, opts})
      {:ok, :delivered}
    end
  end

  setup do
    Application.put_env(:parapet, :use_oban_for_notifications, false)
    Application.put_env(:parapet, :notifiers, [{DummyAdapter, [test_pid: self()]}])
    
    on_exit(fn -> 
      Application.delete_env(:parapet, :use_oban_for_notifications)
      Application.delete_env(:parapet, :notifiers) 
    end)
    :ok
  end

  test "broadcast/1 dispatches to configured adapters" do
    incident = %Parapet.Spine.Incident{id: Ecto.UUID.generate(), title: "Test Incident"}
    
    assert :ok = Parapet.Notifier.broadcast(incident)
    
    assert_receive {:delivered, received_incident, opts}, 1000
    assert received_incident.id == incident.id
    assert opts[:test_pid] == self()
  end
end
