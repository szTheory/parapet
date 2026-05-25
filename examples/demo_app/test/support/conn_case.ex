defmodule DemoAppWeb.ConnCase do
  @moduledoc """
  ExUnit case template for Phoenix controller and LiveView tests.

  Sets up the Ecto sandbox (manual mode, shared for non-async tests) and
  provides a pre-built `conn` for each test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      @endpoint DemoAppWeb.Endpoint
      import Phoenix.LiveViewTest
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DemoApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(DemoApp.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
