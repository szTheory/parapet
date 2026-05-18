defmodule ParapetTest do
  use ExUnit.Case

  alias Parapet.Internal.LabelPolicy

  describe "LabelPolicy.assert_safe!/1" do
    test "allows safe labels" do
      assert :ok == LabelPolicy.assert_safe!([:method, :status, :route])
    end

    test "rejects id labels" do
      assert_raise ArgumentError, ~r/High cardinality label rejected/, fn ->
        LabelPolicy.assert_safe!([:user_id])
      end
    end

    test "rejects raw_ labels" do
      assert_raise ArgumentError, ~r/High cardinality label rejected/, fn ->
        LabelPolicy.assert_safe!([:raw_query])
      end
    end

    test "rejects token labels" do
      assert_raise ArgumentError, ~r/High cardinality label rejected/, fn ->
        LabelPolicy.assert_safe!([:access_token])
      end
    end

    test "rejects path labels" do
      assert_raise ArgumentError, ~r/High cardinality label rejected/, fn ->
        LabelPolicy.assert_safe!([:request_path])
      end
    end
  end

  describe "LabelPolicy.assert_family_keys!/2" do
    test "allows bounded async and delivery metadata keys" do
      assert :ok ==
               LabelPolicy.assert_family_keys!([:parapet, :async, :stage], [
                 :integration,
                 :queue,
                 :pipeline_stage,
                 :outcome,
                 :retry_state,
                 :fault_plane
               ])
    end

    test "rejects refs as public tag keys" do
      assert_raise ArgumentError, ~r/Unsupported public metadata key/, fn ->
        LabelPolicy.assert_family_keys!(:outbound, [:message_ref])
      end
    end
  end

  describe "Parapet.attach/1" do
    test "attaches safely" do
      # Provide a dummy handler module
      defmodule DummyHandler do
        def handle_event(_event, _measurements, _metadata, _config), do: :ok
      end

      assert {:ok, [:my_handler]} ==
               Parapet.attach(%{
                 handler_id: :my_handler,
                 event_name: [:parapet, :test, :event],
                 handler_module: DummyHandler,
                 function_name: :handle_event
               })
    end

    test "activates optional integrations explicitly and repeated activation stays safe" do
      test_pid = self()

      handlers = [
        {"test-phase4-mailglass", [:parapet, :delivery, :outbound]},
        {"test-phase4-chimeway", [:parapet, :delivery, :provider_feedback]},
        {"test-phase4-rindle", [:parapet, :async, :stage]}
      ]

      Enum.each(handlers, fn {handler_id, event_name} ->
        :telemetry.attach(
          handler_id,
          event_name,
          fn name, measurements, metadata, _config ->
            send(test_pid, {:telemetry_event, name, measurements, metadata})
          end,
          nil
        )
      end)

      on_exit(fn ->
        Enum.each(handlers, fn {handler_id, _event_name} ->
          :telemetry.detach(handler_id)
        end)
      end)

      assert {:ok, [:mailglass, :chimeway, :rindle]} ==
               Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])

      assert {:ok, [:mailglass, :chimeway, :rindle]} ==
               Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])

      :telemetry.execute(
        [:mailglass, :outbound, :send, :stop],
        %{duration: 10_000_000},
        %{provider: :ses, message_id: "msg-1", delivery_id: "del-1"}
      )

      :telemetry.execute(
        [:chimeway, :event, :failed],
        %{duration: 10_000_000},
        %{provider: :smtp, error: :rejected, message_id: "msg-2"}
      )

      :telemetry.execute(
        [:rindle, :media, :started],
        %{duration_ms: 12},
        %{queue: "media", pipeline_stage: :ingest, job_id: 11}
      )

      assert_receive {:telemetry_event, [:parapet, :delivery, :outbound], _measurements,
                      %{integration: :mailglass}}

      assert_receive {:telemetry_event, [:parapet, :delivery, :provider_feedback], _measurements,
                      %{integration: :chimeway}}

      assert_receive {:telemetry_event, [:parapet, :async, :stage], _measurements,
                      %{integration: :rindle}}
    end
  end
end
