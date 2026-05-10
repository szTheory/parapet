defmodule Parapet.SLO.Generator do
  @moduledoc """
  Generates Prometheus alerting and recording rules in YAML format
  from `Parapet.SLO` definitions.
  """

  require EEx

  # We use a simple EEx template for the YAML.
  # The template iterates over predefined windows for fast and slow burn.
  # Windows are usually 5m, 30m, 1h, 2h, 6h, 3d.
  # We use a basic subset here for the SLO.
  EEx.function_from_string(
    :defp,
    :render_yaml,
    """
    groups:
      - name: parapet_slo_<%= name %>
        rules:
    <%= for window <- windows do %>
          - record: slo:error_ratio:rate<%= window %>
            expr: >
              sum(rate(<%= good_events %>[<%= window %>])) / sum(rate(<%= total_events %>[<%= window %>]))
            labels:
              slo: <%= name %>
    <% end %>
    """,
    [:name, :good_events, :total_events, :windows]
  )

  @doc """
  Generates YAML for a single SLO.
  """
  def generate_yaml(%Parapet.SLO{} = slo) do
    # Sanitize inputs to avoid YAML injection (T-03-01)
    good_events = sanitize_promql(slo.good_events)
    total_events = sanitize_promql(slo.total_events)

    windows = ["5m", "30m", "1h"]

    render_yaml(slo.name, good_events, total_events, windows)
  end

  defp sanitize_promql(query) do
    # Remove any newlines or characters that could break YAML flow
    query
    |> String.replace(~r/[\n\r]/, " ")
    |> String.trim()
  end
end
