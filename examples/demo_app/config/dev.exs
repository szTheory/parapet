import Config

config :demo_app, DemoAppWeb.Endpoint,
  # Port is env-overridable (default 4000) so the gallery preview can bind a free
  # loopback port without clashing with other local stacks. Bound to 127.0.0.1.
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: false,
  debug_errors: true,
  secret_key_base:
    "demo_app_secret_key_base_for_local_development_only_not_for_production_use_00",
  watchers: []

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
