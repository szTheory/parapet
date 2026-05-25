defmodule DemoAppWeb.Router do
  use DemoAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DemoAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # WARNING: demo only — do not copy to production.
  # Parapet does not provide its own auth.
  # Production deployments must protect these routes with an authenticated scope.
  scope "/" do
    pipe_through :browser

    live_session :parapet_operator do
      live "/parapet", DemoAppWeb.Parapet.OperatorLive, :index
      live "/parapet/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show
    end
  end
end
