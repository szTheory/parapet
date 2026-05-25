defmodule Parapet.Metrics.Validator do
  @moduledoc """
  Compile-time validation for telemetry metrics to prevent TSDB cardinality explosion.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  defmacro __using__(opts) do
    quote do
      @max_labels Keyword.get(unquote(opts), :max_labels, 10)
      @after_compile __MODULE__

      def __after_compile__(env, _bytecode) do
        metrics = apply(env.module, :metrics, [])

        Enum.each(metrics, fn metric ->
          if length(metric.tags) > @max_labels do
            raise CompileError,
              description:
                "Metric #{inspect(metric.name)} exceeds max cardinality limit of #{@max_labels}"
          end

          Parapet.Internal.LabelPolicy.assert_safe!(metric.tags)
        end)
      end
    end
  end
end
