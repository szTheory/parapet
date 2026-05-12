defmodule Parapet.Notifier.SlackTest do
  use ExUnit.Case, async: true
  alias Parapet.Notifier.Slack
  alias Parapet.Spine.Incident

  setup do
    :ok
  end

  test "deliver/2 formats Block Kit with Operator UI link" do
    parent = self()

    Req.Test.stub(SlackTest, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      send(parent, {:slack_request, Jason.decode!(body)})
      Req.Test.json(conn, %{ok: true})
    end)

    incident = %Incident{
      id: "inc_12345",
      title: "API Error Rate High",
      state: "open"
    }

    opts = [
      webhook_url: "https://hooks.slack.com/services/T000/B000/XXX",
      operator_url: "https://operator.example.com",
      req_options: [plug: {Req.Test, SlackTest}]
    ]

    assert {:ok, _response} = Slack.deliver(incident, opts)

    assert_receive {:slack_request, payload}

    # Verify Block Kit structure
    assert is_list(payload["blocks"])

    # Ensure there is a section containing the Operator UI link
    blocks_json = Jason.encode!(payload["blocks"])
    assert blocks_json =~ "https://operator.example.com/incidents/inc_12345"
    assert blocks_json =~ "API Error Rate High"
    assert blocks_json =~ "open"
  end

  test "deliver/2 returns error on non-2xx status" do
    Req.Test.stub(SlackTestError, fn conn ->
      Plug.Conn.send_resp(conn, 500, "internal server error")
    end)

    incident = %Incident{id: "inc_123", title: "Test", state: "open"}
    opts = [
      webhook_url: "https://hooks.slack.com/services/T000/B000/XXX",
      operator_url: "https://operator.example.com",
      req_options: [plug: {Req.Test, SlackTestError}]
    ]

    assert {:error, _reason} = Slack.deliver(incident, opts)
  end
end