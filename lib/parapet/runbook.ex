defmodule Parapet.Runbook do
  @moduledoc """
  A DSL for defining standardized runbooks.

  Runbooks define the manual and automated steps required to mitigate an incident.
  """

  defmacro __using__(_opts) do
    quote do
      import Parapet.Runbook
      Module.register_attribute(__MODULE__, :steps, accumulate: true)
      @before_compile Parapet.Runbook

      def execute_mitigation(_step, _incident), do: {:error, :not_implemented}
      defoverridable execute_mitigation: 2
    end
  end

  defmacro step(id, opts) do
    quote do
      @steps %{
        id: unquote(id),
        label: unquote(opts)[:label],
        description: unquote(opts)[:description],
        type: unquote(opts)[:type],
        kind: unquote(opts)[:kind],
        capability: unquote(opts)[:capability],
        target_kind: unquote(opts)[:target_kind],
        requires_preview: Keyword.get(unquote(opts), :requires_preview, false),
        preview_only: Keyword.get(unquote(opts), :preview_only, false),
        auto_execute: Keyword.get(unquote(opts), :auto_execute, false),
        guidance: unquote(opts)[:guidance]
      }
    end
  end

  defmacro title(title) do
    quote do
      @title unquote(title)
    end
  end

  defmacro description(desc) do
    quote do
      @description unquote(desc)
    end
  end

  defmacro __before_compile__(env) do
    steps = Module.get_attribute(env.module, :steps) |> Enum.reverse()
    title = Module.get_attribute(env.module, :title, "Runbook")
    desc = Module.get_attribute(env.module, :description, "")

    quote do
      def __runbook_schema__() do
        %{
          module: to_string(__MODULE__),
          title: unquote(title),
          description: unquote(desc),
          steps: unquote(Macro.escape(steps))
        }
      end
    end
  end
end
