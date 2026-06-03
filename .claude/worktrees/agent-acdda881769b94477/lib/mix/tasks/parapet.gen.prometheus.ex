defmodule Mix.Tasks.Parapet.Gen.Prometheus do
  @moduledoc """
  Generates valid Prometheus recording and alerting rules based on the user's defined SLOs.
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      defaults: []
    }
  end

  alias Parapet.SLO.Generator

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    artifacts = Generator.provider_artifacts()

    Igniter.create_new_file(
      igniter,
      "priv/parapet/prometheus/recording_rules.yml",
      artifacts.recording_rules
    )
    |> Igniter.create_new_file(
      "priv/parapet/prometheus/alerts.yml",
      artifacts.alerts
    )
    |> Igniter.create_new_file(
      "priv/parapet/prometheus/rules.yml",
      artifacts.rules
    )
  end
end
