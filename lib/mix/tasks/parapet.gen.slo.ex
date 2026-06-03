defmodule Mix.Tasks.Parapet.Gen.Slo do
  @moduledoc """
  Generates a Parapet SLO provider module and registers it.
  """
  use Igniter.Mix.Task

  @example "mix parapet.gen.slo <NAME> --objective 99.9 --good-metric http_requests_total"
  @shortdoc "Generates an SLO provider module"

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :parapet,
      example: @example,
      positional: [:name],
      schema: [
        objective: :float,
        threshold: :float,
        good_metric: :string,
        total_metric: :string,
        alert_class: :string,
        runbook: :string
      ],
      defaults: [
        alert_class: "page",
        runbook: "https://example.com"
      ]
    }
  end

  def igniter(igniter) do
    options = igniter.args.options
    name = igniter.args.positional.name

    unless options[:objective] || options[:threshold] do
      raise ArgumentError, "Must provide either --objective or --threshold"
    end

    module_prefix = Igniter.Project.Module.module_name_prefix(igniter)
    module_name = Module.concat([module_prefix, "SLO", Macro.camelize(name)])

    objective_or_threshold =
      if options[:objective] do
        "objective: #{options[:objective]},"
      else
        "threshold: #{options[:threshold]},"
      end

    good_metric =
      if options[:good_metric],
        do: "good_source_metric: #{inspect(options[:good_metric])},\n",
        else: ""

    total_metric =
      if options[:total_metric],
        do: "total_source_metric: #{inspect(options[:total_metric])},\n",
        else: ""

    alert_class_str = options[:alert_class] || "page"
    runbook_str = options[:runbook] || "https://example.com"

    content = """
    defmodule #{inspect(module_name)} do
      @behaviour Parapet.SLO.Provider

      @impl true
      def slices do
        [
          Parapet.SLO.SliceSpec.new(
            name: #{inspect(name)},
            integration: :custom,
            kind: :ratio,
            #{objective_or_threshold}
            #{good_metric}#{total_metric}alert_class: :#{alert_class_str},
            runbook: #{inspect(runbook_str)}
          )
        ]
      end
    end
    """

    # Clean up any potential double newlines introduced by empty metrics
    content = String.replace(content, ~r/\n\s*\n\s*alert_class:/, "\n        alert_class:")

    igniter
    |> Igniter.Project.Module.create_module(module_name, content)
    |> update_config(module_name)
    |> Igniter.add_notice("Run `mix parapet.gen.prometheus` to emit the new recording rules.")
  end

  defp update_config(igniter, module_name) do
    Igniter.Project.Config.configure(
      igniter,
      "config.exs",
      :parapet,
      [:providers],
      [module_name],
      updater: fn %Sourceror.Zipper{} = zipper ->
        merged =
          zipper
          |> Sourceror.Zipper.node()
          |> Sourceror.to_string()
          |> eval_config_list()
          |> Kernel.++([module_name])
          |> Enum.uniq()

        {:ok, Igniter.Code.Common.replace_code(zipper, inspect(merged))}
      end
    )
  end

  defp eval_config_list(source) do
    case Code.eval_string(source, [], __ENV__) do
      {list, _binding} when is_list(list) -> list
      _ -> []
    end
  end
end
