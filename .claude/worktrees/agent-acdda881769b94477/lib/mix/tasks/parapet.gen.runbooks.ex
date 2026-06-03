defmodule Mix.Tasks.Parapet.Gen.Runbooks do
  @moduledoc """
  Generates a fixed host-owned runbook catalog for Parapet.
  """
  use Igniter.Mix.Task

  @example "mix parapet.gen.runbooks"
  @shortdoc "Generates host-owned runbook modules"

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :parapet,
      example: @example
    }
  end

  def igniter(igniter) do
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    app_name = Igniter.Project.Application.app_name(igniter)

    base_name = web_module |> inspect() |> String.trim_trailing("Web")
    runbook_module_prefix = Module.concat([base_name, "Parapet", "Runbooks"])

    lib_dir = Path.join(["lib", "#{app_name}", "parapet", "runbooks"])

    assigns = [
      app_name: app_name,
      base_name: base_name,
      module_prefix: runbook_module_prefix
    ]

    igniter
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.runbooks",
        "stalled_executor.ex.eex"
      ]),
      Path.join([lib_dir, "stalled_executor.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.runbooks",
        "dead_letter.ex.eex"
      ]),
      Path.join([lib_dir, "dead_letter.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.runbooks",
        "provider_outage.ex.eex"
      ]),
      Path.join([lib_dir, "provider_outage.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.runbooks",
        "callback_delay.ex.eex"
      ]),
      Path.join([lib_dir, "callback_delay.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.runbooks",
        "retry_storm.ex.eex"
      ]),
      Path.join([lib_dir, "retry_storm.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.runbooks",
        "suppression_drift.ex.eex"
      ]),
      Path.join([lib_dir, "suppression_drift.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.runbooks",
        "partial_backlog_drain.ex.eex"
      ]),
      Path.join([lib_dir, "partial_backlog_drain.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.add_notice("""
    Parapet runbooks generated at `#{lib_dir}`.
    You can customize the copy and thresholds to fit your domain.
    """)
  end
end
