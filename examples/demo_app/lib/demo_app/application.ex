defmodule DemoApp.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Gallery-only mode (PARAPET_DEMO_GALLERY_ONLY=true) boots the operator-UI
    # component gallery (/parapet/_gallery) without a database. The gallery renders
    # entirely from in-memory fixtures, so we drop DemoApp.Repo from the tree to allow
    # a zero-infra preview that needs no Postgres. Normal boot is unchanged.
    gallery_only? = System.get_env("PARAPET_DEMO_GALLERY_ONLY") == "true"

    children =
      [
        unless(gallery_only?, do: DemoApp.Repo),
        DemoAppWeb.Telemetry,
        {Peep, name: :parapet_demo_metrics, metrics: DemoApp.ParapetInstrumenter.metrics()},
        {Phoenix.PubSub, name: DemoApp.PubSub},
        DemoAppWeb.Endpoint
      ]
      |> Enum.reject(&is_nil/1)

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
