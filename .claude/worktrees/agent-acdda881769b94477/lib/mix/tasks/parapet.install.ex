defmodule Mix.Tasks.Parapet.Install do
  @moduledoc """
  Installs Parapet into a Phoenix application by scaffolding the host-owned instrumenter
  and wiring it into the endpoint.
  """
  use Igniter.Mix.Task

  alias Igniter.Code.Common
  alias Igniter.Code.Module, as: CodeModule
  alias Igniter.Project.Config
  alias Igniter.Project.Module, as: ProjectModule

  @mailglass_provider Parapet.SLO.MailglassDelivery
  @chimeway_provider Parapet.SLO.ChimewayDelivery
  @core_artifacts [
    "Parapet evidence spine migration",
    "Parapet instrumenter module",
    "Parapet endpoint metrics plug",
    "Parapet deploy hook",
    "Prometheus recording and alert rules"
  ]

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [
        with_ui: :boolean,
        skip_ui: :boolean,
        with_mailglass: :boolean,
        with_chimeway: :boolean,
        with_sigra: :boolean,
        with_scoria: :boolean
      ],
      defaults: [
        with_ui: false,
        skip_ui: false,
        with_mailglass: false,
        with_chimeway: false,
        with_sigra: false,
        with_scoria: false
      ],
      composes: [
        "parapet.gen.spine",
        "parapet.gen.prometheus",
        "parapet.gen.ui",
        "parapet.gen.scoria"
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_module = ProjectModule.module_name_prefix(igniter)
    instrumenter_module = Module.concat([app_module, ParapetInstrumenter])
    web_module = Module.concat([inspect(app_module) <> "Web"])
    endpoint_module = Module.concat([web_module, Endpoint])

    with_ui? = igniter.args.options[:with_ui] || false
    skip_ui? = igniter.args.options[:skip_ui] || false
    with_mailglass? = igniter.args.options[:with_mailglass] || false
    with_chimeway? = igniter.args.options[:with_chimeway] || false
    with_sigra? = igniter.args.options[:with_sigra] || false
    with_scoria? = igniter.args.options[:with_scoria] || false
    live_view_available? = Code.ensure_loaded?(Phoenix.LiveView)

    adapters =
      []
      |> maybe_add(with_mailglass?, :mailglass)
      |> maybe_add(with_chimeway?, :chimeway)

    providers =
      []
      |> maybe_add(with_mailglass?, @mailglass_provider)
      |> maybe_add(with_chimeway?, @chimeway_provider)

    igniter
    |> Igniter.compose_task("parapet.gen.spine", [])
    |> write_instrumenter(instrumenter_module, adapters, with_sigra?)
    |> Config.configure("config.exs", :parapet, [:instrumenter], instrumenter_module)
    |> maybe_configure_providers(providers)
    |> update_endpoint(endpoint_module, web_module)
    |> update_deploy_hook()
    |> Igniter.compose_task("parapet.gen.prometheus", [])
    |> maybe_compose_task(with_scoria?, "parapet.gen.scoria")
    |> maybe_install_ui(with_ui?, skip_ui?, live_view_available?)
    |> Igniter.add_notice(
      install_summary_notice(
        adapters: adapters,
        providers: providers,
        with_ui?: with_ui?,
        skip_ui?: skip_ui?,
        live_view_available?: live_view_available?,
        with_scoria?: with_scoria?
      )
    )
  end

  defp write_instrumenter(igniter, instrumenter_module, adapters, with_sigra?) do
    contents = instrumenter_contents(instrumenter_module, adapters, with_sigra?)
    instrumenter_path = ProjectModule.proper_location(igniter, instrumenter_module)

    Igniter.create_or_update_file(
      igniter,
      instrumenter_path,
      contents,
      fn _existing -> contents end
    )
  end

  defp instrumenter_contents(instrumenter_module, adapters, with_sigra?) do
    adapter_code =
      if adapters == [] do
        []
      else
        ["    Parapet.attach(adapters: #{inspect(adapters)})"]
      end

    sigra_code =
      if with_sigra? do
        [
          "    if Code.ensure_loaded?(Parapet.Integrations.Sigra) do",
          "      Parapet.Integrations.Sigra.setup()",
          "    end"
        ]
      else
        []
      end

    setup_lines =
      [adapter_code, sigra_code, ["    Parapet.Metrics.Probe.setup()", "    :ok"]]
      |> List.flatten()
      |> Enum.join("\n")

    """
    defmodule #{inspect(instrumenter_module)} do
      @moduledoc "Host-owned telemetry instrumentation for Parapet."

      def setup do
    #{setup_lines}
      end
    end
    """
  end

  defp maybe_configure_providers(igniter, []), do: igniter

  defp maybe_configure_providers(igniter, providers) do
    Config.configure(
      igniter,
      "config.exs",
      :parapet,
      [:providers],
      providers,
      updater: fn %Sourceror.Zipper{} = zipper ->
        merged =
          zipper
          |> Sourceror.Zipper.node()
          |> Sourceror.to_string()
          |> eval_config_list()
          |> Kernel.++(providers)
          |> Enum.uniq()

        {:ok, Common.replace_code(zipper, inspect(merged))}
      end
    )
  end

  defp eval_config_list(source) do
    case Code.eval_string(source, [], __ENV__) do
      {list, _binding} when is_list(list) -> list
      _ -> []
    end
  rescue
    _ -> []
  end

  defp maybe_install_ui(igniter, false, _skip_ui?, _live_view_available?), do: igniter
  defp maybe_install_ui(igniter, _with_ui?, true, _live_view_available?), do: igniter

  defp maybe_install_ui(igniter, true, false, true) do
    Igniter.compose_task(igniter, "parapet.gen.ui", [])
  end

  defp maybe_install_ui(igniter, true, false, false) do
    Igniter.add_notice(
      igniter,
      "Skipped extras: UI requested but Phoenix LiveView was not detected, so `parapet.gen.ui` was not composed."
    )
  end

  defp maybe_compose_task(igniter, true, task), do: Igniter.compose_task(igniter, task, [])
  defp maybe_compose_task(igniter, false, _task), do: igniter

  defp install_summary_notice(opts) do
    selected_extras =
      []
      |> maybe_add(
        opts[:with_ui?] && opts[:live_view_available?] && !opts[:skip_ui?],
        "UI workbench"
      )
      |> maybe_add(:mailglass in opts[:adapters], "Mailglass adapter")
      |> maybe_add(:chimeway in opts[:adapters], "Chimeway adapter")
      |> maybe_add(opts[:with_scoria?], "Scoria integration")

    skipped_extras =
      []
      |> maybe_add(!opts[:with_ui?], "UI not selected")
      |> maybe_add(opts[:skip_ui?], "UI explicitly skipped")
      |> maybe_add(
        opts[:with_ui?] && !opts[:live_view_available?],
        "UI requested but LiveView is unavailable"
      )
      |> maybe_add(!(:mailglass in opts[:adapters]), "Mailglass adapter not enabled")
      |> maybe_add(!(:chimeway in opts[:adapters]), "Chimeway adapter not enabled")

    provider_line =
      case opts[:providers] do
        [] -> "Host-owned providers: none added"
        providers -> "Host-owned providers: #{Enum.map_join(providers, ", ", &inspect/1)}"
      end

    """
    Parapet install summary

    Generated core artifacts:
    - #{Enum.join(@core_artifacts, "\n- ")}

    Selected extras:
    - #{Enum.join(default_to_none(selected_extras), "\n- ")}

    Skipped extras:
    - #{Enum.join(default_to_none(skipped_extras), "\n- ")}

    #{provider_line}
    Host follow-up:
    - Review the generated instrumenter module and keep `Parapet.attach(adapters: [...])` host-owned.
    - If you enabled the UI, mount it inside an authenticated scope; Parapet does not provide its own auth.
    - Run `mix parapet.doctor` next.
    """
  end

  defp default_to_none([]), do: ["none"]
  defp default_to_none(items), do: items

  defp maybe_add(list, true, value), do: list ++ [value]
  defp maybe_add(list, false, _value), do: list

  defp update_endpoint(igniter, endpoint_module, web_module) do
    ProjectModule.find_and_update_module!(igniter, endpoint_module, fn zipper ->
      has_plug? = Sourceror.to_string(zipper.node) =~ "Parapet.Plug.Metrics"

      if has_plug? do
        {:ok, zipper}
      else
        insert_plug(zipper, web_module)
      end
    end)
  end

  defp insert_plug(zipper, web_module) do
    case find_insertion_point(zipper, web_module) do
      {:ok, insert_zipper} ->
        {:ok, Common.add_code(insert_zipper, "plug Parapet.Plug.Metrics", placement: :after)}

      :error ->
        {:ok, zipper}
    end
  end

  defp find_insertion_point(zipper, web_module) do
    with :error <- CodeModule.move_to_use(zipper, Phoenix.Endpoint),
         :error <- CodeModule.move_to_use(zipper, web_module) do
      CodeModule.move_to_defmodule(zipper)
    end
  end

  defp update_deploy_hook(igniter) do
    app_name = Igniter.Project.Application.app_name(igniter)

    initial_content = """
    #!/bin/sh

    # Emit deploy marker for Parapet
    bin/#{app_name} rpc "Parapet.Deploy.mark(version: \\"$RELEASE_VERSION\\")"
    """

    updater = fn existing_content ->
      if String.contains?(existing_content, "Parapet.Deploy.mark") do
        existing_content
      else
        existing_content <>
          """

          # Emit deploy marker for Parapet
          bin/#{app_name} rpc "Parapet.Deploy.mark(version: \\"$RELEASE_VERSION\\")"
          """
      end
    end

    Igniter.create_or_update_file(
      igniter,
      "rel/hooks/post_start.sh",
      initial_content,
      updater
    )
  end
end
