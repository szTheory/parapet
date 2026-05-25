defmodule Parapet.Runbook do
  @moduledoc """
  A DSL for defining standardized runbooks.

  Runbooks define the manual and automated steps required to mitigate an incident.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. Its public API will not change without a
  > major-version bump and a full deprecation cycle. See
  > [Stability & Deprecation Policy](stability.html) for details.
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

  @doc since: "1.0.0"
  @doc """
  Defines a single step in the runbook.

  ## Options

    * `:label` - A short human-readable label for the step (string).
    * `:description` - A longer description of what this step involves (string).
    * `:type` - The step type: `:manual` or `:mitigation`.
    * `:kind` - The step kind: `:guidance` or `:capability`.
    * `:capability` - The capability id to invoke for capability-backed mitigation steps
      (one of `:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check`).
    * `:target_kind` - The kind of action item this step targets (atom or string).
    * `:requires_preview` - Whether a preview must be confirmed before execution (boolean, default `false`).
    * `:preview_only` - Whether this step renders as a guidance block with no action button (boolean, default `false`).
    * `:auto_execute` - Whether this step is eligible for automatic execution on alert ingestion (boolean, default `false`).
    * `:guidance` - Advisory text rendered as a blue block in the operator UI when the step is in the `:guidance` state (string).
    * `:warning` - Advisory text rendered as an amber block in the operator UI for any step carrying a precondition or impact warning (string).

  """
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
        guidance: unquote(opts)[:guidance],
        warning: unquote(opts)[:warning]
      }
    end
  end

  @doc since: "1.0.0"
  @doc """
  Sets the runbook title displayed in the operator UI.
  """
  defmacro title(title) do
    quote do
      @title unquote(title)
    end
  end

  @doc since: "1.0.0"
  @doc """
  Sets the runbook description displayed in the operator UI.
  """
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
