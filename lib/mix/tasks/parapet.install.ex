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

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [with_sigra: :boolean],
      defaults: [with_sigra: false]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_module = ProjectModule.module_name_prefix(igniter)
    instrumenter_module = Module.concat([app_module, ParapetInstrumenter])
    web_module = Module.concat([inspect(app_module) <> "Web"])
    endpoint_module = Module.concat([web_module, Endpoint])

    with_sigra? = igniter.args.options[:with_sigra] || false
    with_scoria? = igniter.args.options[:with_scoria] || false

    setup_code_body = []

    setup_code_body =
      if with_sigra? do
        ["  if Code.ensure_loaded?(Parapet.Integrations.Sigra) do\n    Parapet.Integrations.Sigra.setup()\n  end" | setup_code_body]
      else
        setup_code_body
      end

    setup_code_body =
      if with_scoria? do
        ["  if Code.ensure_loaded?(Parapet.Integrations.Scoria) do\n    Parapet.Integrations.Scoria.setup()\n  end" | setup_code_body]
      else
        setup_code_body
      end

    setup_code_body = Enum.reverse(setup_code_body)

    setup_code =
      if setup_code_body == [] do
        """
        def setup do
          # Attach handlers here
          :ok
        end
        """
      else
        """
        def setup do
        #{Enum.join(setup_code_body, "\n")}
          :ok
        end
        """
      end

    igniter =
      if with_scoria? do
        Igniter.compose_task(igniter, "parapet.gen.scoria", [])
      else
        igniter
      end

    igniter
    |> ProjectModule.create_module(
      instrumenter_module,
      """
      @moduledoc "Host-owned telemetry instrumentation for Parapet."

      #{setup_code}
      """
    )
    |> Config.configure(
      "config.exs",
      :parapet,
      [:instrumenter],
      instrumenter_module
    )
    |> update_endpoint(endpoint_module, web_module)
    |> update_deploy_hook()
  end

  defp update_endpoint(igniter, endpoint_module, web_module) do
    ProjectModule.find_and_update_module!(igniter, endpoint_module, fn zipper ->
      # Check if plug is already there
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
