defmodule Parapet.SLO do
  @moduledoc """
  Defines a Service-Level Objective (SLO) within Parapet.
  """

  @enforce_keys [:name, :objective, :good_events, :total_events, :runbook]
  defstruct [:name, :objective, :good_events, :total_events, :runbook]

  @type t :: %__MODULE__{
          name: atom(),
          objective: float(),
          good_events: String.t(),
          total_events: String.t(),
          runbook: String.t()
        }

  @doc """
  Defines a new SLO and stores it in the application registry.

  ## Options

    * `:objective` - The target objective percentage (e.g., 99.9).
    * `:good_events` - PromQL string for good events.
    * `:total_events` - PromQL string for total events.
    * `:runbook` - URL to the runbook for this SLO.

  Raises `ArgumentError` if required fields are missing.
  """
  def define(name, opts) do
    objective = Keyword.get(opts, :objective)
    good_events = Keyword.get(opts, :good_events)
    total_events = Keyword.get(opts, :total_events)
    runbook = Keyword.get(opts, :runbook)

    missing =
      []
      |> append_if_missing(objective, :objective)
      |> append_if_missing(good_events, :good_events)
      |> append_if_missing(total_events, :total_events)
      |> append_if_missing(runbook, :runbook)

    if missing != [] do
      raise ArgumentError, "missing required fields for SLO #{name}: #{inspect(missing)}"
    end

    slo = %__MODULE__{
      name: name,
      objective: objective,
      good_events: good_events,
      total_events: total_events,
      runbook: runbook
    }

    store(slo)
    slo
  end

  @doc """
  Returns all registered SLOs.
  """
  def all do
    Application.get_env(:parapet, :slos, [])
  end

  defp store(slo) do
    slos = all()
    # remove existing with same name and append new
    slos = Enum.reject(slos, &(&1.name == slo.name)) ++ [slo]
    Application.put_env(:parapet, :slos, slos)
  end

  defp append_if_missing(list, nil, field), do: [field | list]
  defp append_if_missing(list, _, _), do: list
end
