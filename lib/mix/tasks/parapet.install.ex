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
      schema: [],
      defaults: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_module = ProjectModule.module_name_prefix(igniter)
    instrumenter_module = Module.concat([app_module, ParapetInstrumenter])
    web_module = Module.concat([inspect(app_module) <> "Web"])
    endpoint_module = Module.concat([web_module, Endpoint])

    igniter
    |> ProjectModule.create_module(
      instrumenter_module,
      """
      @moduledoc "Host-owned telemetry instrumentation for Parapet."

      def setup do
        # Attach handlers here
        :ok
      end
      """
    )
    |> Config.configure(
      "config.exs",
      :parapet,
      [:instrumenter],
      instrumenter_module
    )
    |> update_endpoint(endpoint_module, web_module)
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
end
