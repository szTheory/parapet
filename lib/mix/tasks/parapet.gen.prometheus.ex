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

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    # Register built-in SLOs
    Parapet.SLO.HTTP.register()

    if Code.ensure_loaded?(Oban) do
      Parapet.SLO.Oban.register()
    end

    Parapet.SLO.LoginJourney.register()

    slos = Parapet.SLO.all()

    windows = ["5m", "30m", "1h", "2h", "6h", "3d"]

    template_path =
      Application.app_dir(:parapet, "priv/templates/parapet.gen.prometheus/rules.yml.eex")

    yaml_content = EEx.eval_file(template_path, slos: slos, windows: windows)

    Igniter.create_new_file(
      igniter,
      "priv/parapet/prometheus/rules.yml",
      yaml_content
    )
  end
end
