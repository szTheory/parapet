import Config

config :demo_app, DemoApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "demo_app_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :demo_app, DemoAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "demo_app_secret_key_base_for_local_development_only_not_for_production_use_00",
  server: false

config :logger, level: :warning
