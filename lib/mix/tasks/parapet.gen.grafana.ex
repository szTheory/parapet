defmodule Mix.Tasks.Parapet.Gen.Grafana do
  @moduledoc """
  Generates importable Grafana dashboards and provisioning YAML based on the user's SLOs.
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      defaults: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    # Register built-in SLOs
    Parapet.SLO.HTTP.register()

    if Code.ensure_loaded?(Oban) do
      Parapet.SLO.Oban.register()
    end

    Parapet.SLO.LoginJourney.register()

    slos = Parapet.SLO.all()

    app_name = Igniter.Project.Application.app_name(igniter) || :parapet_app

    # Generate Dashboards Provisioning YAML
    provisioning_template =
      Application.app_dir(:parapet, "priv/templates/parapet.gen.grafana/dashboards.yml.eex")

    provisioning_content = EEx.eval_file(provisioning_template, app_name: app_name)

    igniter =
      Igniter.create_new_file(
        igniter,
        "priv/parapet/grafana/provisioning/dashboards.yml",
        provisioning_content
      )

    # Generate Main Dashboard JSON
    dashboard_template =
      Application.app_dir(:parapet, "priv/templates/parapet.gen.grafana/main_dashboard.json.eex")

    dashboard_content = EEx.eval_file(dashboard_template, app_name: app_name, slos: slos)

    Igniter.create_new_file(
      igniter,
      "priv/parapet/grafana/dashboards/main.json",
      dashboard_content
    )
  end
end
