defmodule Parapet.Notifier.Slack do
  @moduledoc """
  Slack adapter for Parapet notifications.
  Sends rich Block Kit messages for incident updates.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  @behaviour Parapet.Notifier

  @impl true
  def deliver(incident, opts) do
    webhook_url = Keyword.get(opts, :webhook_url)
    operator_url = Keyword.get(opts, :operator_url)
    req_options = Keyword.get(opts, :req_options, [])

    if is_nil(webhook_url) do
      {:error, "Missing webhook_url in options"}
    else
      payload = build_payload(incident, operator_url)

      Req.post(req_options, url: webhook_url, json: payload)
      |> case do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, "HTTP #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp build_payload(incident, operator_url) do
    incident_url =
      if operator_url do
        base = String.trim_trailing(operator_url, "/")
        "#{base}/incidents/#{incident.id}"
      else
        "URL not configured"
      end

    %{
      "blocks" => [
        %{
          "type" => "header",
          "text" => %{
            "type" => "plain_text",
            "text" => "Parapet Incident: #{incident.state}",
            "emoji" => true
          }
        },
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" =>
              "*Title:* #{incident.title}\n*Status:* #{incident.state}\n*ID:* #{incident.id}"
          }
        },
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" => "<#{incident_url}|View in Operator UI>"
          }
        }
      ]
    }
  end
end
