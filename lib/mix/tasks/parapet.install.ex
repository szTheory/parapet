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
    app_module = Igniter.Project.Application.app_module(igniter)
    instrumenter_module = Module.concat([app_module, ParapetInstrumenter])
    web_module = Module.concat([app_module, "Web"])
    endpoint_module = Module.concat([web_module, Endpoint])

    igniter
    |> Igniter.Project.Module.create_module(
      instrumenter_module,
      """
      defmodule #{inspect(instrumenter_module)} do
        @moduledoc "Host-owned telemetry instrumentation for Parapet."

        def setup do
          # Attach handlers here
          :ok
        end
      end
      """
    )
    |> Igniter.Project.Config.configure(
      "config.exs",
      :parapet,
      [:instrumenter],
      {:__aliases__, [alias: false], [app_module, :ParapetInstrumenter]}
    )
    |> update_endpoint(endpoint_module)
  end

  defp update_endpoint(igniter, endpoint_module) do
    Igniter.Project.Module.find_and_update_module!(igniter, endpoint_module, fn zipper ->
      # Check if plug is already there
      has_plug? = Sourceror.to_string(zipper.node) =~ "Parapet.Plug.Metrics"

      if has_plug? do
        {:ok, zipper}
      else
        # Move to use Phoenix.Endpoint or any module ending in Web, :endpoint
        # A safer bet is just move inside the module block and prepend
        case Igniter.Code.Module.move_to_module_using(zipper, Phoenix.Endpoint) do
          {:ok, use_zipper} ->
            {:ok, Igniter.Code.Common.add_code(use_zipper, "plug Parapet.Plug.Metrics", placement: :after)}

          :error ->
            # Fallback if use Phoenix.Endpoint isn't found exactly (e.g. use MyAppWeb, :endpoint)
            # Find the module definition and insert at the top of its block
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
