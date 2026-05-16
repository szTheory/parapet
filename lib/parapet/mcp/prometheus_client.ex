defmodule Parapet.MCP.PrometheusClient do
  @moduledoc """
  A read-only Prometheus HTTP API proxy using `Req` to allow external agents
  to retrieve predefined time-series metrics.
  """

  @doc """
  Fetches the SLO burn rate for a given SLO name using a hardcoded, safe
  PromQL query. Returns the parsed Prometheus API response.

  Options:
    * `:req_options` - additional options to pass to `Req.request/1` (e.g. for testing)
  """
  def get_slo_burn_rate(name, opts \\ []) do
    case Application.get_env(:parapet, :prometheus_url) do
      nil ->
        {:error, :not_configured}

      url ->
        # Use a hardcoded PromQL query format and inject only the sanitized name
        # to avoid arbitrary PromQL injection from external agents.
        query = "rate(parapet_slo_events_total{slo=\"#{sanitize_label(name)}\"}[5m])"

        req_options =
          opts
          |> Keyword.get(:req_options, [])
          |> Keyword.merge(
            base_url: url,
            url: "/api/v1/query",
            params: [query: query]
          )

        case Req.get(req_options) do
          {:ok, %Req.Response{status: 200, body: body}} ->
            {:ok, body}

          {:ok, %Req.Response{status: status}} ->
            {:error, {:bad_status, status}}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp sanitize_label(name) do
    # Remove any quotes or characters that could break out of the label value string
    String.replace(name, ~r/[^a-zA-Z0-9_:-]/, "")
  end
end