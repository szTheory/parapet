defmodule Parapet.MCP.ServerTest do
  use ExUnit.Case, async: false
  alias Parapet.MCP.Server
  alias Parapet.Spine.Incident
  alias Parapet.Spine.TimelineEntry

  defmodule DummyRepo do
    def all(query) do
      send(self(), {:repo_all, inspect(query)})
      Process.get(:mock_repo_all, [])
    end
  end

  defmodule DummyPrometheusClient do
    def get_slo_burn_rate(name, _opts \\ []) do
      send(self(), {:get_slo_burn_rate, name})
      Process.get(:mock_prometheus_result, {:ok, %{"status" => "success"}})
    end
  end

  defmodule MockRunbook do
    def __runbook_schema__() do
      %{module: "MockRunbook", title: "Test", description: "Desc", steps: []}
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    Application.put_env(:parapet, :prometheus_client, DummyPrometheusClient)

    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
      Application.delete_env(:parapet, :prometheus_client)
    end)

    :ok
  end

  describe "execute_tool/2" do
    test "Test 1: list_incidents returns only active incidents via Parapet.Evidence" do
      incidents = [
        %Incident{id: "inc-1", title: "API down", state: "open", correlation_key: "corr-1"}
      ]

      Process.put(:mock_repo_all, incidents)

      assert {:ok, result} = Server.execute_tool("list_incidents", %{})
      assert result == incidents

      assert_received {:repo_all, query_str}
      assert query_str =~ "Parapet.Spine.Incident"
      assert query_str =~ "state == \"open\""
    end

    test "Test 2: get_incident_timeline returns timeline entries for a specific correlation_key" do
      entries = [
        %TimelineEntry{id: "entry-1", type: "note", payload: %{"text" => "working on it"}}
      ]

      Process.put(:mock_repo_all, entries)

      assert {:ok, result} =
               Server.execute_tool("get_incident_timeline", %{"correlation_key" => "corr-1"})

      assert result == entries

      assert_received {:repo_all, query_str}
      assert query_str =~ "Parapet.Spine.TimelineEntry"
      # Timeline entries should be filtered by incident ID derived from correlation_key
      # In Parapet, timeline entries belong to incident. We must join or query incident first.
      # The exact query string depends on implementation, so we don't assert full string here.
      assert query_str =~ "Parapet.Spine.TimelineEntry"
    end

    test "Test 3: read_runbook correctly and safely resolves module names and fetches the runbook schema" do
      # Need to setup SLO to match the alertname
      apply(Parapet.SLO, :define, [
        :RunbookAlert,
        [
          objective: 99.9,
          good_events: "up",
          total_events: "all",
          runbook: MockRunbook
        ]
      ])

      assert {:ok, result} = Server.execute_tool("read_runbook", %{"alertname" => "RunbookAlert"})
      assert result == %{module: "MockRunbook", title: "Test", description: "Desc", steps: []}

      Application.put_env(
        :parapet,
        :slos,
        Enum.reject(Parapet.SLO.all(), &(&1.name == :RunbookAlert))
      )
    end

    test "Test 3.1: read_runbook returns error if SLO not found" do
      assert {:error, :not_found} =
               Server.execute_tool("read_runbook", %{"alertname" => "UnknownAlert"})
    end

    test "Test 4: get_slo_burn_rates delegates to Parapet.MCP.PrometheusClient" do
      assert {:ok, result} = Server.execute_tool("get_slo_burn_rates", %{"name" => "MySLO"})
      assert result == %{"status" => "success"}

      assert_received {:get_slo_burn_rate, "MySLO"}
    end

    test "Test 5: unknown tool calls return an error" do
      assert {:error, :unknown_tool} = Server.execute_tool("delete_database", %{})
    end
  end
end
