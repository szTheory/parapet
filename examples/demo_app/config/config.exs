import Config

config :parapet,
  repo: DemoApp.Repo,
  providers: [Parapet.SLO.StarterPack.WebSaaS]

config :demo_app,
  ecto_repos: [DemoApp.Repo]

config :demo_app, DemoApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "demo_app_dev",
  pool_size: 10

config :demo_app, DemoAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  secret_key_base: "demo_app_secret_key_base_for_local_development_only_not_for_production_use_00",
  render_errors: [formats: [html: DemoAppWeb.ErrorHTML], layout: false],
  pubsub_server: DemoApp.PubSub,
  live_view: [signing_salt: "demo_salt"]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
