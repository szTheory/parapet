ExUnit.start()

config = Parapet.TestSupport.ConcurrencyRepo.database_config()

case Ecto.Adapters.Postgres.storage_up(config) do
  :ok -> :ok
  {:error, :already_up} -> :ok
  {:error, {:already_started, _pid}} -> :ok
end

{:ok, _pid} = Parapet.TestSupport.ConcurrencyRepo.start_link(config)
Parapet.TestSupport.ConcurrencyBootstrap.bootstrap!()
Ecto.Adapters.SQL.Sandbox.mode(Parapet.TestSupport.ConcurrencyRepo, :manual)
