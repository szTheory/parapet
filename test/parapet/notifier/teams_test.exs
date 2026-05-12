defmodule Parapet.Notifier.TeamsTest do
  use ExUnit.Case, async: true
  alias Parapet.Notifier.Teams
  alias Parapet.Spine.Incident

  setup do
    :ok
  end

  test "deliver/2 formats Adaptive Card with Operator UI link" do
    parent = self()

    Req.Test.stub(TeamsTest, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      send(parent, {:teams_request, Jason.decode!(body)})
      Req.Test.json(conn, %{ok: true})
    end)

    incident = %Incident{
      id: "inc_12345",
      title: "DB Connection Pool Exhausted",
      state: "open"
    }

    opts = [
      webhook_url: "https://foo.webhook.office.com/webhookb2/XXX",
      operator_url: "https://operator.example.com",
      req_options: [plug: {Req.Test, TeamsTest}]
    ]

    assert {:ok, _response} = Teams.deliver(incident, opts)

    assert_receive {:teams_request, payload}

    # Verify Adaptive Card structure
    assert payload["type"] == "message"
    assert is_list(payload["attachments"])

    # Ensure there is a section containing the Operator UI link
    payload_json = Jason.encode!(payload)
    assert payload_json =~ "https://operator.example.com/incidents/inc_12345"
    assert payload_json =~ "DB Connection Pool Exhausted"
    assert payload_json =~ "open"
    assert payload_json =~ "AdaptiveCard"
  end

  test "deliver/2 returns error on non-2xx status" do
    Req.Test.stub(TeamsTestError, fn conn ->
      Plug.Conn.send_resp(conn, 500, "internal server error")
    end)

    incident = %Incident{id: "inc_123", title: "Test", state: "open"}

    opts = [
      webhook_url: "https://foo.webhook.office.com/webhookb2/XXX",
      operator_url: "https://operator.example.com",
      req_options: [plug: {Req.Test, TeamsTestError}]
    ]

    assert {:error, _reason} = Teams.deliver(incident, opts)
  end
end
