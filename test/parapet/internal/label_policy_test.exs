defmodule Parapet.Internal.LabelPolicyTest do
  use ExUnit.Case, async: true

  alias Parapet.Internal.LabelPolicy

  describe "assert_safe!/1" do
    test "permits allowed labels" do
      labels = [:route, :method, :status_class, :queue, :worker, :state]
      assert :ok = LabelPolicy.assert_safe!(labels)

      # Also test string representations if needed
      assert :ok = LabelPolicy.assert_safe!(["route", "method"])
    end

    test "raises ArgumentError on high-cardinality labels ending with 'id'" do
      assert_raise ArgumentError,
                   ~r/High cardinality label rejected by Parapet safety policy/,
                   fn ->
                     LabelPolicy.assert_safe!([:user_id, :route])
                   end

      assert_raise ArgumentError,
                   ~r/High cardinality label rejected by Parapet safety policy/,
                   fn ->
                     LabelPolicy.assert_safe!(["account_id"])
                   end
    end

    test "raises ArgumentError on high-cardinality labels starting with 'raw_'" do
      assert_raise ArgumentError,
                   ~r/High cardinality label rejected by Parapet safety policy/,
                   fn ->
                     LabelPolicy.assert_safe!([:raw_data])
                   end

      assert_raise ArgumentError,
                   ~r/High cardinality label rejected by Parapet safety policy/,
                   fn ->
                     LabelPolicy.assert_safe!(["raw_path"])
                   end
    end

    test "raises ArgumentError on high-cardinality labels containing 'token'" do
      assert_raise ArgumentError,
                   ~r/High cardinality label rejected by Parapet safety policy/,
                   fn ->
                     LabelPolicy.assert_safe!([:session_token])
                   end

      assert_raise ArgumentError,
                   ~r/High cardinality label rejected by Parapet safety policy/,
                   fn ->
                     LabelPolicy.assert_safe!(["token"])
                   end
    end

    test "raises ArgumentError on high-cardinality labels containing 'path'" do
      assert_raise ArgumentError,
                   ~r/High cardinality label rejected by Parapet safety policy/,
                   fn ->
                     LabelPolicy.assert_safe!([:path])
                   end

      assert_raise ArgumentError,
                   ~r/High cardinality label rejected by Parapet safety policy/,
                   fn ->
                     LabelPolicy.assert_safe!(["request_path"])
                   end
    end
  end
end
