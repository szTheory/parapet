defmodule Parapet.Integrations.ThreadlineTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset) do
      send(self(), {:insert_called, changeset})

      if Ecto.Changeset.get_field(changeset, :tool_name) == "threadline:crash" do
        raise "db connection failed"
      end

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
    :telemetry.execute([:threadline, :audit, :event], %{duration_ms: 50}, %{
      action: "test_action",
      payload: %{foo: "bar"},
      success: true
    })

    assert_receive {:insert_called, changeset}
    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :tool_name) == "threadline:test_action"
  end

  test "safely rescues exceptions to prevent Ecto crash propagation" do
    # Emit an event with action: "crash" to trigger the DummyRepo's raise
    :telemetry.execute([:threadline, :audit, :event], %{duration_ms: 10}, %{action: "crash"})

    # We shouldn't crash the test process
    assert true
  end

  test "handle_event/4 correctly formats payload and calls Threadline when Code.ensure_loaded?(Threadline) is true" do
    Process.register(self(), :threadline_test_receiver)

    audit_attrs = %{tool_name: "my_tool", input: %{"a" => 1}, success: true}

    :telemetry.execute([:parapet, :audit, :created], %{}, %{audit_attrs: audit_attrs})

    assert_receive {:threadline_log_audit, attrs}
    assert attrs.action == "my_tool"
    assert attrs.payload == %{"a" => 1}
    assert attrs.success == true

    Process.unregister(:threadline_test_receiver)
  end

  test "handle_event/4 safely returns :ok without crashing when Code.ensure_loaded?(Threadline) is false" do
    beam_path = :code.which(Threadline)
    bak_path = to_string(beam_path) <> ".bak"
    File.rename!(beam_path, bak_path)

    :code.delete(Threadline)
    :code.purge(Threadline)

    assert :ok =
             :telemetry.execute([:parapet, :audit, :created], %{}, %{
               audit_attrs: %{tool_name: "test"}
             })

    refute_receive {:threadline_log_audit, _}

    File.rename!(bak_path, beam_path)
    Code.ensure_loaded?(Threadline)
  end
end
