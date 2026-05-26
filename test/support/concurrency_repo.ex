defmodule Parapet.TestSupport.ConcurrencyRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :parapet,
    adapter: Ecto.Adapters.Postgres

  def database_config do
    [
      username: System.get_env("PARAPET_CONCURRENCY_DB_USER", "postgres"),
      password: System.get_env("PARAPET_CONCURRENCY_DB_PASSWORD", "postgres"),
      hostname: System.get_env("PARAPET_CONCURRENCY_DB_HOST", "localhost"),
      port: String.to_integer(System.get_env("PARAPET_CONCURRENCY_DB_PORT", "5432")),
      database: System.get_env("PARAPET_CONCURRENCY_DB_NAME", "parapet_concurrency_test"),
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_size: 10,
      ownership_timeout: 30_000,
      stacktrace: true,
      show_sensitive_data_on_connection_error: true
    ]
  end
end
