defmodule Parapet.Recovery do
  @moduledoc """
  Behaviour for host-app recovery action modules.

  Every recovery action module that registers with Parapet implements this behaviour.
  Host applications activate their recovery actions via `Parapet.Recovery.attach/1`,
  which registers each loaded module's capabilities into `Parapet.Capabilities`.

  Declare `use Parapet.Recovery` in a host module to inject `@behaviour Parapet.Recovery`
  and surface any missing or mis-named callbacks as compile-time warnings via Dialyzer.

  The four callbacks (`id/0`, `label/0`, `preview/2`, `execute/2`) define the complete
  contract a recovery action module must implement. The activation entry point is
  `Parapet.Recovery.attach/1`.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @doc since: "1.1.0"
  @doc """
  Returns the unique atom identifier for this recovery action.

  The atom must be in the allowlist declared by `Parapet.Capabilities`. Attempting to
  register an id not in the allowlist raises an `ArgumentError` at attach time.
  """
  @callback id() :: atom()

  @doc since: "1.1.0"
  @doc """
  Returns the human-readable display name for this recovery action.

  Used as the `name:` key in the capabilities registry and displayed in the Operator UI.
  """
  @callback label() :: String.t()

  @doc since: "1.1.0"
  @doc """
  Previews the effect of executing this recovery action for the given incident and step.

  Returns `{:ok, preview_map}` with a map of preview data for the Operator UI to display,
  or `{:error, reason}` if the preview cannot be computed.
  """
  @callback preview(incident :: any(), step :: any()) :: {:ok, map()} | {:error, term()}

  @doc since: "1.1.0"
  @doc """
  Executes this recovery action against the given incident and target refs.

  Returns `{:ok, result_map}` on success or `{:error, reason}` on failure.
  This function is invoked only after an operator confirms the action via the Operator UI.
  """
  @callback execute(incident :: any(), target_refs :: any()) :: {:ok, map()} | {:error, term()}

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Parapet.Recovery
    end
  end

  @doc since: "1.1.0"
  @doc """
  Activates a list of host recovery action modules by registering each loaded module
  into `Parapet.Capabilities`.

  Modules where `Code.ensure_loaded?/1` returns `false` are silently skipped — no
  log, no warning, no error. This mirrors the optional-dependency skip pattern used
  by `Parapet.attach/1` and the ecosystem integration adapters.

  For each loaded module, `attach/1` calls `module.id/0` and `module.label/0` once at
  attach time, captures `&module.preview/2` and `&module.execute/2` as anonymous-function
  captures, and delegates to `Parapet.Capabilities.register_recovery/2`.

  Returns `{:ok, registered_ids}` where `registered_ids` is the list of `id()` atoms
  actually registered (in the order registration occurred). Silently skipped modules are
  absent from the list. If zero modules are loaded, returns `{:ok, []}` — not an error.

  ## Example

      Parapet.Recovery.attach([MyApp.Recovery.RetryAsyncItem, SomeMissingModule])
      # => {:ok, [:retry_async_item]}
  """
  def attach(modules) when is_list(modules) do
    registered =
      modules
      |> Enum.filter(&Code.ensure_loaded?/1)
      |> Enum.map(fn module ->
        id = module.id()
        label = module.label()

        :ok =
          Parapet.Capabilities.register_recovery(id,
            name: label,
            module: module,
            preview: &module.preview/2,
            execute: &module.execute/2
          )

        id
      end)

    {:ok, registered}
  end
end
