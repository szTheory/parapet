defmodule DemoAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :demo_app

  @session_options [
    store: :cookie,
    key: "_demo_app_key",
    signing_salt: "demo_signing",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :demo_app,
    gzip: false,
    only: DemoAppWeb.static_paths()

  if code_reloading? do
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  plug Parapet.Plug.Metrics

  plug DemoAppWeb.Router
end
