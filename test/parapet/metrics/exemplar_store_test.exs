defmodule Parapet.Metrics.ExemplarStoreTest do
  use ExUnit.Case, async: false

  alias Parapet.Metrics.ExemplarStore

  setup do
    start_supervised!(ExemplarStore)
    :ok
  end

  test "records and retrieves trace ID for a metric and tags" do
    assert ExemplarStore.get_trace("http_requests", %{route: "/api"}) == nil

    ExemplarStore.record_trace("http_requests", %{route: "/api"}, "trace-123")
    assert ExemplarStore.get_trace("http_requests", %{route: "/api"}) == "trace-123"
  end

  test "overwrites previous trace ID for exact same combination" do
    ExemplarStore.record_trace("http_requests", %{route: "/api"}, "trace-123")
    ExemplarStore.record_trace("http_requests", %{route: "/api"}, "trace-456")

    assert ExemplarStore.get_trace("http_requests", %{route: "/api"}) == "trace-456"
  end

  test "different metric/tags get separate trace IDs" do
    ExemplarStore.record_trace("http_requests", %{route: "/api"}, "trace-123")
    ExemplarStore.record_trace("db_query", %{table: "users"}, "trace-789")

    assert ExemplarStore.get_trace("http_requests", %{route: "/api"}) == "trace-123"
    assert ExemplarStore.get_trace("db_query", %{table: "users"}) == "trace-789"
  end
end
