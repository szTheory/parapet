defmodule Mix.Tasks.Parapet.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Igniter.Mix.Task.Args
  alias Mix.Tasks.Parapet.Install

  describe "mix parapet.install" do
    test "declares the unified install contract and composed generators" do
      info = Install.info([], nil)

      assert info.composes == [
               "parapet.gen.spine",
               "parapet.gen.prometheus",
               "parapet.gen.ui",
               "parapet.gen.scoria"
             ]

      assert info.schema[:with_ui] == :boolean
      assert info.schema[:skip_ui] == :boolean
      assert info.schema[:with_mailglass] == :boolean
      assert info.schema[:with_chimeway] == :boolean
    end

    test "composes the core paved-road flow and patches the endpoint idempotently" do
      igniter =
        test_project(app_name: :test)
        |> with_options([])
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

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))

      assert Enum.any?(files, &String.contains?(&1, "add_parapet_spine_tables"))
      assert "priv/parapet/prometheus/recording_rules.yml" in files
      assert "priv/parapet/prometheus/alerts.yml" in files

      endpoint_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/endpoint.ex")
        |> Rewrite.Source.get(:content)

      assert endpoint_source =~ "plug(Parapet.Plug.Metrics)"
      assert [_, _] = String.split(endpoint_source, "plug(Parapet.Plug.Metrics)")

      config_source =
        Rewrite.source!(igniter.rewrite, "config/config.exs")
        |> Rewrite.Source.get(:content)

      assert config_source =~ "instrumenter: Test.ParapetInstrumenter"

      install_source = File.read!("lib/mix/tasks/parapet.install.ex")
      assert String.contains?(install_source, "Igniter.compose_task(\"parapet.gen.spine\"")
      assert String.contains?(install_source, "Igniter.compose_task(\"parapet.gen.prometheus\"")
      assert String.contains?(install_source, "with_ui: :boolean")

      spine_index =
        install_source
        |> :binary.match("Igniter.compose_task(\"parapet.gen.spine\"")
        |> elem(0)

      prometheus_index =
        install_source
        |> :binary.match("Igniter.compose_task(\"parapet.gen.prometheus\"")
        |> elem(0)

      assert spine_index < prometheus_index
    end

    test "enables optional extras explicitly, keeps providers host-owned, and emits a trust summary" do
      igniter =
        test_project(app_name: :test)
        |> with_options(with_ui: true, with_mailglass: true, with_chimeway: true)
        |> Igniter.Project.Module.create_module(TestWeb.Endpoint, """
        use TestWeb, :endpoint

        plug Plug.RequestId
        """)
        |> Install.igniter()

      instrumenter_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet_instrumenter.ex")
        |> Rewrite.Source.get(:content)

      assert instrumenter_source =~ "Parapet.attach(adapters: [:mailglass, :chimeway])"

      config_source =
        Rewrite.source!(igniter.rewrite, "config/config.exs")
        |> Rewrite.Source.get(:content)

      assert config_source =~ "Parapet.SLO.MailglassDelivery"
      assert config_source =~ "Parapet.SLO.ChimewayDelivery"

      mixfile_source =
        Rewrite.source!(igniter.rewrite, "mix.exs")
        |> Rewrite.Source.get(:content)

      refute mixfile_source =~ "mailglass"
      refute mixfile_source =~ "chimeway"

      assert Enum.any?(
               igniter.notices,
               &String.contains?(&1, "Parapet install summary")
             )

      assert Enum.any?(
               igniter.notices,
               &String.contains?(&1, "Selected extras:")
             )

      assert Enum.any?(
               igniter.notices,
               &String.contains?(&1, "mix parapet.doctor")
             )

      assert Enum.any?(
               igniter.notices,
               &String.contains?(&1, "Parapet does not provide its own auth")
             )

      assert Enum.any?(
               igniter.notices,
               &String.contains?(&1, "live_session :parapet_operator")
             )
    end
  end

  defp with_options(igniter, options) do
    %Args{} = args = igniter.args
    %{igniter | args: %{args | options: options}}
  end
end
