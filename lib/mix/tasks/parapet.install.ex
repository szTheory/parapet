defmodule Mix.Tasks.Parapet.Install do
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      defaults: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_module = Igniter.Project.Module.module_name_prefix(igniter)
    instrumenter_module = Module.concat([app_module, ParapetInstrumenter])
    web_module = Module.concat([inspect(app_module) <> "Web"])
    endpoint_module = Module.concat([web_module, Endpoint])

    igniter
    |> Igniter.Project.Module.create_module(
      instrumenter_module,
      """
      @moduledoc "Host-owned telemetry instrumentation for Parapet."

      def setup do
        # Attach handlers here
        :ok
      end
      """
    )
    |> Igniter.Project.Config.configure(
      "config.exs",
      :parapet,
      [:instrumenter],
      instrumenter_module
    )
    |> update_endpoint(endpoint_module, web_module)
  end

  defp update_endpoint(igniter, endpoint_module, web_module) do
    Igniter.Project.Module.find_and_update_module!(igniter, endpoint_module, fn zipper ->
      # Check if plug is already there
      has_plug? = Sourceror.to_string(zipper.node) =~ "Parapet.Plug.Metrics"

      if has_plug? do
        {:ok, zipper}
      else
        use_zipper_res =
          case Igniter.Code.Module.move_to_use(zipper, Phoenix.Endpoint) do
            {:ok, z} -> {:ok, z}
            :error -> Igniter.Code.Module.move_to_use(zipper, web_module)
          end

        case use_zipper_res do
          {:ok, use_zipper} ->
            {:ok, Igniter.Code.Common.add_code(use_zipper, "plug Parapet.Plug.Metrics", placement: :after)}

          :error ->
            # Fallback to inserting at the top of the module block
            case Igniter.Code.Module.move_to_defmodule(zipper) do
              {:ok, def_zipper} ->
                {:ok, Igniter.Code.Common.add_code(def_zipper, "plug Parapet.Plug.Metrics", placement: :after)}
              :error ->
                {:ok, zipper}
            end
        end
      end
    end)
  end
end
