defmodule Parapet.Plug.Webhook do
  @moduledoc """
  A Plug to receive webhooks from Alertmanager and route them to the AlertProcessor.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
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
