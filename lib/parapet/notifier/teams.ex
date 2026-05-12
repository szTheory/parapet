defmodule Parapet.Notifier.Teams do
  @moduledoc """
  MS Teams adapter for Parapet notifications.
  Sends rich Adaptive Cards for incident updates.
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
      "type" => "message",
      "attachments" => [
        %{
          "contentType" => "application/vnd.microsoft.card.adaptive",
          "contentUrl" => nil,
          "content" => %{
            "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
            "type" => "AdaptiveCard",
            "version" => "1.4",
            "body" => [
              %{
                "type" => "TextBlock",
                "text" => "Parapet Incident: #{incident.state}",
                "weight" => "Bolder",
                "size" => "Medium"
              },
              %{
                "type" => "FactSet",
                "facts" => [
                  %{"title" => "Title:", "value" => incident.title},
                  %{"title" => "Status:", "value" => incident.state},
                  %{"title" => "ID:", "value" => incident.id}
                ]
              }
            ],
            "actions" => [
              %{
                "type" => "Action.OpenUrl",
                "title" => "View in Operator UI",
                "url" => incident_url
              }
            ]
          }
        }
      ]
    }
  end
end
