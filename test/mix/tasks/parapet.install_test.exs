defmodule Mix.Tasks.Parapet.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Install

  describe "mix parapet.install" do
    test "generates instrumenter module, updates config, and patches endpoint" do
      igniter =
        test_project(app_name: :test)
        |> Igniter.Project.Module.create_module(TestWeb.Endpoint, """
        use TestWeb, :endpoint

        plug Plug.RequestId
        """)
        |> Install.igniter()

      assert_creates(igniter, "lib/test/parapet_instrumenter.ex", """
      defmodule Test.ParapetInstrumenter do
        @moduledoc "Host-owned telemetry instrumentation for Parapet."

        def setup do
          Parapet.Metrics.Probe.setup()
          :ok
        end
      end
      """)
      # Assert updates using the updated sources from igniter.rewrite
      endpoint_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/endpoint.ex")
        |> Rewrite.Source.get(:content)

      assert endpoint_source =~ "plug(Parapet.Plug.Metrics)"

      config_source =
        Rewrite.source!(igniter.rewrite, "config/config.exs")
        |> Rewrite.Source.get(:content)

      assert config_source =~ "config :parapet, instrumenter: Test.ParapetInstrumenter"
    end

    test "is idempotent and does not patch endpoint twice" do
      igniter =
        test_project(app_name: :test)
        |> Igniter.Project.Module.create_module(TestWeb.Endpoint, """
        use TestWeb, :endpoint

        plug Parapet.Plug.Metrics
        plug Plug.RequestId
        """)
        |> Install.igniter()

      endpoint_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/endpoint.ex")
        |> Rewrite.Source.get(:content)

      # Should only contain the plug once
      assert [_, _] = String.split(endpoint_source, "plug(Parapet.Plug.Metrics)")
    end
  end
end
