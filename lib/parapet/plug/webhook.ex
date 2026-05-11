defmodule Parapet.Plug.Webhook do
  @moduledoc """
  A Plug to receive webhooks from Alertmanager and route them to the AlertProcessor.
  """

  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%{method: "POST"} = conn, _opts) do
    payload = conn.body_params || %{}
    Parapet.Spine.AlertProcessor.process_batch(payload)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(202, Jason.encode!(%{"status" => "accepted"}))
  end

  @impl true
  def call(conn, _opts) do
    conn
    |> send_resp(405, "")
  end
end
