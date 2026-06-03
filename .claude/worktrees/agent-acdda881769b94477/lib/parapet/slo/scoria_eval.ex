defmodule Parapet.SLO.ScoriaEval do
  @moduledoc """
  Defines an SLO based on Scoria AI evaluation pass rates.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @enforce_keys [:name, :objective, :guardrail, :runbook]
  defstruct [:name, :objective, :guardrail, :runbook, labels: %{}]

  @type t :: %__MODULE__{
          name: atom(),
          objective: float(),
          guardrail: String.t(),
          runbook: String.t(),
          labels: map()
        }

  @doc """
  Builds a new ScoriaEval struct and validates required properties.
  """
  def new(opts) do
    name = Keyword.get(opts, :name)
    objective = Keyword.get(opts, :objective)
    guardrail = Keyword.get(opts, :guardrail)
    runbook = Keyword.get(opts, :runbook)
    labels = Keyword.get(opts, :labels, %{})

    missing =
      []
      |> append_if_missing(objective, :objective)
      |> append_if_missing(guardrail, :guardrail)
      |> append_if_missing(runbook, :runbook)
      |> Enum.reverse()

    if missing != [] do
      raise ArgumentError, "missing required fields for ScoriaEval #{name}: #{inspect(missing)}"
    end

    %__MODULE__{
      name: name,
      objective: objective,
      guardrail: guardrail,
      runbook: runbook,
      labels: labels
    }
  end

  defp append_if_missing(list, nil, field), do: [field | list]
  defp append_if_missing(list, _, _), do: list
end

defimpl Parapet.SLO.Resolvable, for: Parapet.SLO.ScoriaEval do
  def to_slo(eval) do
    labels_str = format_labels(eval.labels)

    good_events =
      "sum(rate(scoria_evaluation_total{guardrail=\"#{eval.guardrail}\", passed=\"true\"#{labels_str}}[window]))"

    total_events =
      "sum(rate(scoria_evaluation_total{guardrail=\"#{eval.guardrail}\"#{labels_str}}[window]))"

    %Parapet.SLO{
      name: eval.name,
      objective: eval.objective,
      good_events: good_events,
      total_events: total_events,
      runbook: eval.runbook
    }
  end

  defp format_labels(labels) when map_size(labels) == 0, do: ""

  defp format_labels(labels) do
    labels_str =
      labels
      |> Enum.map(fn {k, v} -> "#{k}=\"#{v}\"" end)
      |> Enum.join(", ")

    ", #{labels_str}"
  end
end
