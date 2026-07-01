defmodule Mix.Tasks.Parapet.InstallTest do
  # async: false because Application.put_env is used in setup blocks to control
  # :schema_prefix config state, which is global and not safe in concurrent tests.
  use ExUnit.Case, async: false
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

  # GEN-05 install leg: --schema routes through install → composed gen.spine
  describe "mix parapet.install --schema (GEN-05 install leg)" do
    setup do
      # Reset schema_prefix before and after so config-state tests are deterministic.
      # (Pitfall 5 from 53-RESEARCH.md: use put_env in setup for conflict-adjacent assertions)
      Application.put_env(:parapet, :schema_prefix, nil)
      on_exit(fn -> Application.put_env(:parapet, :schema_prefix, "parapet") end)
      :ok
    end

    # GEN-05: the --schema flag routed through install's group: :parapet reaches the composed
    # gen.spine, which resolves the prefix and stamps it on generated DDL (D-08, D-15).
    test "GEN-05: --schema custom routes to composed gen.spine — prefixed DDL and config written" do
      igniter =
        test_project(app_name: :test)
        |> with_options(schema: "custom", create_schema: true)
        |> Igniter.Project.Module.create_module(TestWeb.Endpoint, """
        use TestWeb, :endpoint
        plug Plug.RequestId
        """)
        |> Install.igniter()

      # The composed gen.spine must have written config :parapet, :schema_prefix, "custom"
      config_source =
        Rewrite.source!(igniter.rewrite, "config/config.exs")
        |> Rewrite.Source.get(:content)

      assert config_source =~ "schema_prefix",
             "Expected config/config.exs to contain schema_prefix after install --schema custom"

      assert config_source =~ "custom",
             "Expected schema_prefix to be 'custom' in config/config.exs after install --schema custom"

      # The composed gen.spine must have stamped prefix: "custom" in the generated migration
      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
      migration_file = Enum.find(files, &String.contains?(&1, "add_parapet_spine_tables.exs"))

      assert migration_file,
             "Expected add_parapet_spine_tables.exs to be generated by the composed gen.spine"

      migration_source =
        Rewrite.source!(igniter.rewrite, migration_file)
        |> Rewrite.Source.get(:content)

      # prefix: "custom" must appear on tables/references/indexes (GEN-02, D-01)
      assert migration_source =~ ~s[prefix: "custom"],
             "Expected prefix: \"custom\" in generated spine migration (schema forwarded via group: :parapet)"

      # Sentinel migration is created (create_schema: true)
      assert_creates(igniter, "priv/repo/migrations/00000000000000_create_parapet_schema.exs")
    end

    # GEN-04/GEN-05: --no-create-schema forwarded through install → composed gen.spine omits
    # the sentinel migration while still stamping prefix: on the DDL (D-15, GEN-04).
    test "GEN-04/GEN-05: --no-create-schema forwarded to composed gen.spine — sentinel omitted, DDL still prefixed" do
      igniter =
        test_project(app_name: :test)
        |> with_options(create_schema: false)
        |> Igniter.Project.Module.create_module(TestWeb.Endpoint, """
        use TestWeb, :endpoint
        plug Plug.RequestId
        """)
        |> Install.igniter()

      # GEN-04: sentinel migration NOT created (--no-create-schema forwarded to gen.spine)
      refute_creates(igniter, "priv/repo/migrations/00000000000000_create_parapet_schema.exs")

      # GEN-02: spine migration is still generated and prefix-stamped (default "parapet")
      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))
      migration_file = Enum.find(files, &String.contains?(&1, "add_parapet_spine_tables.exs"))

      assert migration_file,
             "Expected add_parapet_spine_tables.exs to be generated even under --no-create-schema"

      migration_source =
        Rewrite.source!(igniter.rewrite, migration_file)
        |> Rewrite.Source.get(:content)

      # Tables are still prefix-stamped (default resolver returns "parapet" when no flag)
      assert migration_source =~ ~s[prefix: "parapet"],
             "Expected prefix: \"parapet\" in generated spine migration even under --no-create-schema"
    end
  end

  defp with_options(igniter, options) do
    %Args{} = args = igniter.args
    # Build the raw argv_flags list from the options keyword list so that
    # compose_task/2 can re-parse them into the composed task's args.options.
    # This mirrors what Igniter does at the CLI: parse argv → options.
    argv_flags =
      Enum.flat_map(options, fn
        {key, false} -> ["--no-#{dasherize(key)}"]
        {key, true} -> ["--#{dasherize(key)}"]
        {key, value} -> ["--#{dasherize(key)}", to_string(value)]
      end)

    %{igniter | args: %{args | options: options, argv_flags: argv_flags}}
  end

  defp dasherize(key), do: key |> to_string() |> String.replace("_", "-")
end
