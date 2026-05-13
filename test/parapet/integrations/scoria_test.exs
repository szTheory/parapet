defmodule Parapet.Integrations.ScoriaTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset) do
      # Send to the test process (assuming synchronous execution)
      # We look up the test pid using a registered name or just assume
      # telemetry is executed in the same process, which it is.
      send(self(), {:dummy_repo_insert, changeset})
      
      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      else
        {:error, changeset}
      end
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    
    # Detach any existing handlers to prevent duplicate errors between tests
    :telemetry.detach("parapet-scoria-telemetry")
    Parapet.Integrations.Scoria.setup()

    test_pid = self()
    handler_id = "test-parapet-scoria-metrics-#{System.unique_integer()}"

    :telemetry.attach(
      handler_id,
      [:parapet, :scoria, :metrics],
      fn name, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)
      :telemetry.detach("parapet-scoria-telemetry")
      Application.delete_env(:parapet, :repo)
    end)

    :ok
  end

  test "setup/0 attaches handler to [:scoria, :sre, :telemetry] without error" do
    handlers = :telemetry.list_handlers([:scoria, :sre, :telemetry])
    assert Enum.any?(handlers, fn h -> h.id == "parapet-scoria-telemetry" end)
  end

  test "handle_event/4 translates successful events to [:parapet, :scoria, :metrics], extracting low cardinality labels" do
    metadata = %{
      model: "gpt-4",
      provider: "openai",
      tool_name: "test_tool",
      trace_id: "high_cardinality_12345",
      other_data: "should_be_dropped"
    }

    :telemetry.execute([:scoria, :sre, :telemetry], %{duration: 100}, metadata)

    assert_receive {:telemetry_event, [:parapet, :scoria, :metrics], %{duration: 100}, received_meta}
    
    # Check that low cardinality labels are kept
    assert received_meta.model == "gpt-4"
    assert received_meta.provider == "openai"
    assert received_meta.tool_name == "test_tool"
    
    # Check that outcome is computed correctly
    assert received_meta.outcome == :success
    
    # Check that high cardinality labels are dropped
    refute Map.has_key?(received_meta, :trace_id)
    refute Map.has_key?(received_meta, :other_data)
  end

  test "handle_event/4 computes outcome as :failure when :error is present" do
    metadata = %{
      model: "gpt-4",
      provider: "openai",
      tool_name: "test_tool",
      error: %RuntimeError{message: "boom"}
    }

    :telemetry.execute([:scoria, :sre, :telemetry], %{duration: 100}, metadata)

    assert_receive {:telemetry_event, [:parapet, :scoria, :metrics], %{duration: 100}, received_meta}
    assert received_meta.outcome == :failure
  end

  test "handle_event/4 routes errors to Parapet.Evidence.create_incident/1" do
    error_struct = %RuntimeError{message: "boom"}
    metadata = %{
      model: "gpt-4",
      provider: "openai",
      tool_name: "test_tool",
      error: error_struct
    }

    :telemetry.execute([:scoria, :sre, :telemetry], %{duration: 100}, metadata)

    assert_receive {:dummy_repo_insert, changeset}
    assert changeset.data.__struct__ == Parapet.Spine.Incident
    
    # Description should contain the inspected error
    description = Ecto.Changeset.get_field(changeset, :description)
    assert description =~ "RuntimeError"
    assert description =~ "boom"
    
    # The title should probably indicate a Scoria failure
    title = Ecto.Changeset.get_field(changeset, :title)
    assert title =~ "Scoria" || title =~ "test_tool" || title =~ "AI"
  end

  test "handle_event/4 rescues any exceptions during processing to prevent crashing the host process" do
    # Intentionally pass bad data that would cause a crash if not rescued
    # In Elixir, Map.take on a non-map raises, for example. We can call handle_event directly
    # with a non-map metadata to force an exception.
    
    # Should not raise
    assert Parapet.Integrations.Scoria.handle_event(
             [:scoria, :sre, :telemetry],
             %{duration: 100},
             :not_a_map,
             nil
           ) == :ok
  end
end
