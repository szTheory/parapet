defmodule Mix.Tasks.Verify.PublicApi do
  @moduledoc """
  Verifies that all public API modules have documentation and a stability-tier
  declaration, and generates a manifest.

  Each public Parapet module must include an ExDoc admonition callout in its
  `@moduledoc` to declare its stability tier:

  - Stable: `> #### Stable {: .info}`
  - Experimental: `> #### Experimental {: .warning}`

  Modules in the `Parapet.Internal.*` or `Parapet.TestSupport.*` namespaces and
  modules containing `.Resolvable.` in their name are excluded from this check.
  """
  use Mix.Task

  @shortdoc "Verifies public API module documentation and stability-tier declarations"

  @impl Mix.Task
  def run(_args) do
    # Ensure application is compiled and loaded
    Mix.Task.run("compile")
    Application.load(:parapet)

    {:ok, modules} = :application.get_key(:parapet, :modules)

    manifest =
      modules
      |> Enum.filter(&public_api_module?/1)
      |> Enum.map(&check_module/1)
      |> Enum.sort_by(& &1.module)

    # Encode to JSON if Jason is available, otherwise use inspect
    output =
      if Code.ensure_loaded?(Jason) do
        Jason.encode!(manifest, pretty: true)
      else
        inspect(manifest, pretty: true, limit: :infinity)
      end

    IO.puts(output)

    # `@moduledoc false` (Code.fetch_docs/1 -> :hidden) maps to the :internal
    # tier and is an intentional way to mark a public-namespace module internal.
    # Treat it as a deliberate exclusion, not a missing-documentation failure.
    missing_docs = Enum.filter(manifest, fn m -> not m.has_docs and m.tier != :internal end)

    if missing_docs != [] do
      IO.puts(:stderr, "Error: One or more public API modules are missing documentation.")
      IO.puts(:stderr, Enum.map_join(missing_docs, "\n", &"  - #{&1.module}"))
      System.halt(1)
    end

    unclassified = Enum.filter(manifest, fn m -> m.tier == :unclassified end)

    if unclassified != [] do
      IO.puts(:stderr, "Error: One or more public API modules are missing a stability-tier declaration.")

      IO.puts(
        :stderr,
        "Add '> #### Stable {: .info}' or '> #### Experimental {: .warning}' to each @moduledoc."
      )

      IO.puts(:stderr, Enum.map_join(unclassified, "\n", &"  - #{&1.module}"))
      System.halt(1)
    end
  end

  defp public_api_module?(module) do
    name = inspect(module)

    (String.starts_with?(name, "Parapet.") or name == "Parapet") and
      not String.starts_with?(name, "Parapet.Internal.") and
      not String.starts_with?(name, "Parapet.TestSupport.") and
      not String.contains?(name, ".Resolvable")
  end

  defp check_module(module) do
    {has_docs, tier} =
      case Code.fetch_docs(module) do
        {:docs_v1, _, _, _, :hidden, _, _} -> {false, :internal}
        {:docs_v1, _, _, _, :none, _, _} -> {false, :unclassified}
        {:docs_v1, _, _, _, %{"en" => text}, _, _} -> {true, detect_tier_from_text(text)}
        {:error, _} -> {false, :unclassified}
      end

    %{module: inspect(module), has_docs: has_docs, tier: tier}
  end

  @doc false
  def detect_tier_from_text(text) do
    cond do
      String.contains?(text, "{: .info}") and String.contains?(text, "Stable") ->
        :stable

      String.contains?(text, "{: .warning}") and String.contains?(text, "Experimental") ->
        :experimental

      true ->
        :unclassified
    end
  end
end
