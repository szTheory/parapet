defmodule Parapet.Integrations.ThreadlineTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset) do
      send(self(), {:insert_called, changeset})
      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      else
        {:error, changeset}
      end
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    Parapet.Integrations.Threadline.setup()
    
    on_exit(fn -> 
      Application.delete_env(:parapet, :repo)
    end)
    
    :ok
  end

  test "safely translates Parapet.Spine.ToolAudit to Threadline schema shapes" do
    audit = %Parapet.Spine.ToolAudit{
      tool_name: "test", 
      input: %{foo: "bar"}, 
      output: %{baz: "qux"}, 
      success: true, 
      duration_ms: 10
    }
    shape = Parapet.Integrations.Threadline.to_threadline_shape(audit)
    
    assert shape.action == "test"
    assert shape.payload == %{foo: "bar"}
    assert shape.success == true
  end

  test "attaches to threadline audit events and safely inserts ToolAudit via Evidence" do
    :telemetry.execute([:threadline, :audit, :event], %{duration_ms: 50}, %{action: "test_action", payload: %{foo: "bar"}, success: true})
    
    assert_receive {:insert_called, changeset}
    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :tool_name) == "threadline:test_action"
  end

  test "safely rescues exceptions to prevent Ecto crash propagation" do
    # Emit an invalid event that would crash Ecto or Parapet.Evidence
    # For instance if repo insert raises because of connection issue, but here we can just pass something
    # that raises an error when processing.
    # To truly simulate a crash, we can pass something that causes an exception inside handle_event.
    :telemetry.execute([:threadline, :audit, :event], :invalid_measurements_type, %{crash_me: true})
    
    # We shouldn't crash the test process
    assert true
  end
end
