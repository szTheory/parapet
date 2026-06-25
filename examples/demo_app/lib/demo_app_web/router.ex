defmodule DemoAppWeb.Router do
  use DemoAppWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {DemoAppWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  # WARNING: demo only — do not copy to production.
  # Parapet does not provide its own auth.
  # Production deployments must protect these routes with an authenticated scope.
  scope "/" do
    pipe_through(:browser)

    # Gallery must be declared before the "/parapet/:id" catch-all below —
    # Phoenix matches routes in declaration order, so an earlier ":id" route
    # would otherwise capture "_gallery" as an incident id (Ecto binary_id cast error).
    live_session :parapet_gallery do
      live("/parapet/_gallery", DemoAppWeb.Parapet.GalleryLive, :index)
    end

    live_session :parapet_operator do
      live("/parapet", DemoAppWeb.Parapet.OperatorLive, :index)
      live("/parapet/actions", DemoAppWeb.Parapet.OperatorLive, :actions)
      live("/parapet/history", DemoAppWeb.Parapet.OperatorLive, :history)
      live("/parapet/incidents/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)
      live("/parapet/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)
    end
  end

  scope "/ops" do
    pipe_through(:browser)

    live_session :parapet_operator_scoped do
      live("/parapet", DemoAppWeb.Parapet.OperatorLive, :index)
      live("/parapet/actions", DemoAppWeb.Parapet.OperatorLive, :actions)
      live("/parapet/history", DemoAppWeb.Parapet.OperatorLive, :history)
      live("/parapet/incidents/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)
      live("/parapet/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)
    end
  end
end
