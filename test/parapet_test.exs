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
  end
end
