defmodule Parapet.MCP.PrometheusClientTest do
  use ExUnit.Case, async: false

  alias Parapet.MCP.PrometheusClient

  setup do
    original_url = Application.get_env(:parapet, :prometheus_url)

    on_exit(fn ->
      if original_url do
        Application.put_env(:parapet, :prometheus_url, original_url)
      else
        Application.delete_env(:parapet, :prometheus_url)
      end
    end)

    :ok
  end

  describe "get_slo_burn_rate/1" do
    test "returns error when Prometheus URL is not configured" do
      Application.delete_env(:parapet, :prometheus_url)

      assert {:error, :not_configured} = PrometheusClient.get_slo_burn_rate("my_slo")
    end

    test "makes correct HTTP GET request via Req with hardcoded parameterized query" do
      Application.put_env(:parapet, :prometheus_url, "http://localhost:9090")

      plug = fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.request_path == "/api/v1/query"
        query = conn.query_params["query"]
        assert query =~ "my_slo"
        # Ensure it's doing some rate query
        assert query =~ "rate("

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          ~s({"status":"success","data":{"resultType":"vector","result":[{"metric":{},"value":[1715694000,"0.1"]}]}})
        )
      end

      assert {:ok, result} =
               PrometheusClient.get_slo_burn_rate("my_slo", req_options: [plug: plug])

      assert result["status"] == "success"
      assert result["data"]["resultType"] == "vector"
    end
  end
end
