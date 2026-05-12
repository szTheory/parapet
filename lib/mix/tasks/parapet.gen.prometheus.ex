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

  alias Parapet.SLO

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    # Register built-in SLOs
    SLO.HTTP.register()

    if Code.ensure_loaded?(Oban) do
      SLO.Oban.register()
    end

    SLO.LoginJourney.register()

    slos = SLO.all()

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
