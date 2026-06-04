defmodule DemoApp.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DemoApp.Repo,
      DemoAppWeb.Telemetry,
      {Peep, name: :parapet_demo_metrics, metrics: DemoApp.ParapetInstrumenter.metrics()},
      {Phoenix.PubSub, name: DemoApp.PubSub},
      DemoAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: DemoApp.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, opts)

    # Parapet.Capabilities is started by the :parapet OTP application (Parapet.Internal.Application).
    # attach/1 is safe to call here because the named singleton is already running at this point.
    DemoApp.ParapetInstrumenter.setup()
    {:ok, _} = Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])
    {:ok, sup}
  end

  @impl true
  def config_change(changed, _new, removed) do
    DemoAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
