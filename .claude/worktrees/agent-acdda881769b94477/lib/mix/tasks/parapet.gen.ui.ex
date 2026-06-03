defmodule Mix.Tasks.Parapet.Gen.Ui do
  @moduledoc """
  Generates Parapet operator UI components for the host Phoenix application.
  """
  use Igniter.Mix.Task

  @example "mix parapet.gen.ui"
  @shortdoc "Generates a host-owned LiveView operator workbench for Parapet"

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :parapet,
      example: @example
    }
  end

  def igniter(igniter) do
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    app_name = Igniter.Project.Application.app_name(igniter)

    # E.g. web_module is MyAppWeb, we want MyApp.Repo
    base_name = web_module |> inspect() |> String.trim_trailing("Web")
    repo_module = Module.concat([base_name, "Repo"])

    web_dir = Path.join(["lib", "#{app_name}_web", "live", "parapet"])

    assigns = [
      web_module: web_module,
      app_name: app_name,
      repo_module: repo_module
    ]

    igniter
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.ui",
        "operator_live.ex.eex"
      ]),
      Path.join([web_dir, "operator_live.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.ui",
        "operator_detail_live.ex.eex"
      ]),
      Path.join([web_dir, "operator_detail_live.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.ui",
        "operator_components.ex.eex"
      ]),
      Path.join([web_dir, "operator_components.ex"]),
      assigns,
      on_exists: :skip
    )
    |> add_router_guidance(assigns)
  end

  defp add_router_guidance(igniter, assigns) do
    template_path =
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.ui",
        "router_snippet.ex.eex"
      ])

    # Try to safely evaluate the template
    guidance =
      if File.exists?(template_path) do
        EEx.eval_file(template_path, assigns: assigns)
      else
        # Fallback for testing when priv/ isn't compiled yet or when running tests
        """
        # Ensure you place these routes inside an existing authenticated scope,
        # or define a new pipeline with your app's standard authentication plugs.
        # Parapet does not provide its own auth.
        #
        # Example:
        # scope "/admin", #{inspect(assigns[:web_module])} do
        #   pipe_through [:browser, :require_authenticated_user]
        #
        #   live_session :parapet_operator,
        #     on_mount: [{#{inspect(assigns[:web_module])}.UserAuth, :ensure_authenticated}] do
        #
        #     live "/parapet", Parapet.OperatorLive.Index, :index
        #     live "/parapet/:id", Parapet.OperatorDetailLive.Show, :show
        #   end
        # end
        """
      end

    Igniter.add_notice(igniter, guidance)
  end
end
