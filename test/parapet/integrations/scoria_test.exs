defmodule Scoria.Workflow do
  def get_state(id) do
    Process.get({:scoria_workflow_state, id}, :active)
  end
end

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

    def update_all(query, updates) do
      send(self(), {:dummy_repo_update_all, query, updates})
      {1, nil}
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)

    # Detach any existing handlers to prevent duplicate errors between tests
    :telemetry.detach("parapet-scoria-telemetry")
    :telemetry.detach("parapet-scoria-config-telemetry")
    :telemetry.detach("parapet-scoria-mcp-telemetry")
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

    :telemetry.attach_many(
      "#{handler_id}-workflow",
      [
        [:parapet, :scoria, :metrics, :stale],
        [:parapet, :scoria, :metrics, :expired],
        [:parapet, :scoria, :metrics, :resumed]
      ],
      fn name, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("#{handler_id}-workflow")
      :telemetry.detach(handler_id)
      :telemetry.detach("parapet-scoria-telemetry")
      :telemetry.detach("parapet-scoria-config-telemetry")
      :telemetry.detach("parapet-scoria-mcp-telemetry")
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

    assert_receive {:telemetry_event, [:parapet, :scoria, :metrics], %{duration: 100},
                    received_meta}

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

    assert_receive {:telemetry_event, [:parapet, :scoria, :metrics], %{duration: 100},
                    received_meta}

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

  describe "[:scoria, :config, :deployed] telemetry" do
    test "delegates to Parapet.Evidence.create_incident/1 with type config_change" do
      metadata = %{
        scorer_version: "v1.2",
        baseline_version: "v1.0",
        model: "gpt-4"
      }

      :telemetry.execute([:scoria, :config, :deployed], %{}, metadata)

      assert_receive {:dummy_repo_insert, changeset}
      assert changeset.data.__struct__ == Parapet.Spine.Incident
      assert Ecto.Changeset.get_field(changeset, :title) == "AI Config Deployed"
      assert Ecto.Changeset.get_field(changeset, :state) == "open"

      runbook_data = Ecto.Changeset.get_field(changeset, :runbook_data)
      assert runbook_data["type"] == "config_change"
      assert runbook_data["scorer_version"] == "v1.2"
      assert runbook_data["baseline_version"] == "v1.0"
      assert runbook_data["model"] == "gpt-4"
    end
  end

  describe "[:scoria, :mcp, :tool, :exception] telemetry" do
    setup do
      test_pid = self()
      handler_id = "test-parapet-mcp-error-#{System.unique_integer()}"

      :telemetry.attach(
        handler_id,
        [:parapet, :scoria, :mcp, :error],
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

    test "maps known error reasons safely and emits [:parapet, :scoria, :mcp, :error]" do
      metadata = %{
        tool_name: "fetch_data",
        error: %{reason: :timeout}
      }

      :telemetry.execute([:scoria, :mcp, :tool, :exception], %{duration: 50}, metadata)

      assert_receive {:telemetry_event, [:parapet, :scoria, :mcp, :error], %{duration: 50},
                      received_meta}

      assert received_meta.reason == "timeout"
      assert received_meta.tool_name == "fetch_data"
    end

    test "unknown reasons fall back to 'execution_failed'" do
      metadata = %{
        tool_name: "fetch_data",
        error: %{reason: :weird_unknown_error}
      }

      :telemetry.execute([:scoria, :mcp, :tool, :exception], %{duration: 50}, metadata)

      assert_receive {:telemetry_event, [:parapet, :scoria, :mcp, :error], %{duration: 50},
                      received_meta}

      assert received_meta.reason == "execution_failed"
      assert received_meta.tool_name == "fetch_data"
    end
  end

  describe "[:scoria, :workflow, :stale] and [:scoria, :workflow, :expired] telemetry" do
    test "staleness event emits [:parapet, :scoria, :metrics, :stale] and calls Evidence.create_action_item" do
      metadata = %{
        workflow_id: "wf_stale_123",
        model: "gpt-4"
      }

      :telemetry.execute(
        [:scoria, :workflow, :stale],
        %{scoria_workflow_stale_total: 1},
        metadata
      )

      assert_receive {:telemetry_event, [:parapet, :scoria, :metrics, :stale],
                      %{scoria_workflow_stale_total: 1}, received_meta}

      assert received_meta.workflow_id == "wf_stale_123"

      assert_receive {:dummy_repo_insert, changeset}
      assert changeset.data.__struct__ == Parapet.Spine.ActionItem
      assert Ecto.Changeset.get_field(changeset, :integration) == "scoria"
      assert Ecto.Changeset.get_field(changeset, :external_id) == "wf_stale_123"
      assert Ecto.Changeset.get_field(changeset, :title) =~ "Workflow wf_stale_123 is stale"
    end

    test "expiration event emits [:parapet, :scoria, :metrics, :expired]" do
      metadata = %{
        workflow_id: "wf_expired_123",
        model: "gpt-4"
      }

      :telemetry.execute(
        [:scoria, :workflow, :expired],
        %{scoria_workflow_expired_total: 1},
        metadata
      )

      assert_receive {:telemetry_event, [:parapet, :scoria, :metrics, :expired],
                      %{scoria_workflow_expired_total: 1}, received_meta}

      assert received_meta.workflow_id == "wf_expired_123"
    end
  end

  describe "[:scoria, :workflow, :resumed] telemetry and check_status/1" do
    test "resume event checks external state before closing the action item" do
      workflow_id = "wf_resumed_123"

      metadata = %{
        workflow_id: workflow_id,
        model: "gpt-4"
      }

      # Setup mock state to return :paused, meaning it's still paused and shouldn't be closed
      Process.put({:scoria_workflow_state, workflow_id}, :paused)

      :telemetry.execute(
        [:scoria, :workflow, :resumed],
        %{scoria_workflow_resumed_total: 1},
        metadata
      )

      assert_receive {:telemetry_event, [:parapet, :scoria, :metrics, :resumed],
                      %{scoria_workflow_resumed_total: 1}, received_meta}

      assert received_meta.workflow_id == workflow_id

      # Since it's still :paused, it shouldn't update the repo
      refute_receive {:dummy_repo_update_all, _query, _updates}

      # Now change the mock state to return :active, meaning it's no longer paused
      Process.put({:scoria_workflow_state, workflow_id}, :active)

      :telemetry.execute(
        [:scoria, :workflow, :resumed],
        %{scoria_workflow_resumed_total: 1},
        metadata
      )

      # It should now resolve the action item
      assert_receive {:dummy_repo_update_all, _query, updates}

      # The update should set state: "resolved"
      assert updates == [set: [state: "resolved"]]
    end
  end
end
