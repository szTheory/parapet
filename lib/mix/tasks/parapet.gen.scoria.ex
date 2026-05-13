defmodule Mix.Tasks.Parapet.Gen.Scoria do
  @moduledoc """
  Generates Grafana dashboards and Prometheus rules for Parapet's Scoria AI telemetry integration.
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      defaults: [],
      required: [],
      aliases: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    dashboard_template = Path.join(:code.priv_dir(:parapet), "templates/parapet.gen.scoria/scoria_dashboard.json.eex")
    rules_template = Path.join(:code.priv_dir(:parapet), "templates/parapet.gen.scoria/rules.yml.eex")

    dashboard_content = EEx.eval_file(dashboard_template)
    rules_content = EEx.eval_file(rules_template)

    igniter
    |> Igniter.create_new_file("priv/parapet/grafana/dashboards/scoria_dashboard.json", dashboard_content)
    |> Igniter.create_new_file("priv/parapet/prometheus/rules.yml", rules_content)
  end
end
