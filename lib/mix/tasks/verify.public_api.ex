defmodule Mix.Tasks.Verify.PublicApi do
  @moduledoc """
  Verifies that all public API modules have documentation and a stability-tier
  declaration, and checks the committed Stable API manifest.

  Each public Parapet module must include an ExDoc admonition callout in its
  `@moduledoc` to declare its stability tier:

  - Stable: `> #### Stable {: .info}`
  - Experimental: `> #### Experimental {: .warning}`

  Modules in the `Parapet.Internal.*` or `Parapet.TestSupport.*` namespaces and
  modules containing `.Resolvable` in their name are excluded from this check.
  (This also catches the terminal protocol module `Parapet.SLO.Resolvable` and
  its auto-generated `defimpl` dispatch modules.)
  """
  use Mix.Task

  @shortdoc "Verifies public API module documentation and stability-tier declarations"

  @stable_manifest_path "priv/parapet/public_api_stable.json"

  @impl Mix.Task
  def run(args) do
    write_manifest? = "--write" in args

    # Ensure application is compiled and loaded
    Mix.Task.run("compile")
    Application.load(:parapet)

    {:ok, modules} = :application.get_key(:parapet, :modules)

    manifest =
      modules
      |> Enum.filter(&public_api_module?/1)
      |> Enum.map(&check_module/1)
      |> Enum.sort_by(& &1.module)

    # The manifest is a machine-readable artifact, so it must always be emitted in
    # one canonical format (pretty JSON). Fail loudly if Jason is unavailable
    # rather than silently degrading to `inspect`, which would produce a second,
    # non-interchangeable representation that downstream diffs cannot compare.
    unless Code.ensure_loaded?(Jason) do
      IO.puts(
        :stderr,
        "Error: Jason is required to emit the public-API manifest as canonical JSON. " <>
          "Add {:jason, \"~> 1.0\"} to your deps and run `mix deps.get`."
      )

      System.halt(1)
    end

    output = Jason.encode!(manifest, pretty: true)

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
      IO.puts(
        :stderr,
        "Error: One or more public API modules are missing a stability-tier declaration."
      )

      IO.puts(
        :stderr,
        "Add '> #### Stable {: .info}' or '> #### Experimental {: .warning}' to each @moduledoc."
      )

      IO.puts(:stderr, Enum.map_join(unclassified, "\n", &"  - #{&1.module}"))
      System.halt(1)
    end

    stable_manifest =
      manifest
      |> Enum.filter(&(&1.tier == :stable))
      |> Enum.map(&Map.delete(&1, :has_docs))
      |> Enum.sort_by(& &1.module)

    stable_output = Jason.encode!(stable_manifest, pretty: true)

    if write_manifest? do
      File.mkdir_p!(Path.dirname(@stable_manifest_path))
      File.write!(@stable_manifest_path, stable_output <> "\n")
    else
      verify_stable_manifest!(stable_output)
    end
  end

  defp verify_stable_manifest!(stable_output) do
    case File.read(@stable_manifest_path) do
      {:ok, expected} ->
        if String.trim(expected) != String.trim(stable_output) do
          IO.puts(
            :stderr,
            "Error: Stable public API manifest drifted. " <>
              "Run `mix verify.public_api --write` only for intentional, reviewed API changes."
          )

          System.halt(1)
        end

      {:error, reason} ->
        IO.puts(
          :stderr,
          "Error: Stable public API manifest missing at #{@stable_manifest_path}: #{inspect(reason)}. " <>
            "Run `mix verify.public_api --write` to create it."
        )

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

    %{
      module: inspect(module),
      has_docs: has_docs,
      tier: tier,
      callbacks: callbacks(module),
      functions: exported_functions(module),
      macros: exported_macros(module),
      struct_keys: struct_keys(module)
    }
  end

  @doc false
  def detect_tier_from_text(text) do
    # Anchor the tier keyword and its admonition class to the SAME callout line
    # so an unrelated `{: .info}` callout plus the word "Stable" elsewhere in the
    # moduledoc cannot misclassify the module. The `####` heading and class must
    # co-occur in one admonition (e.g. `> #### Stable {: .info}`).
    cond do
      Regex.match?(~r/####\s+Stable\s*\{:\s*\.info\}/, text) -> :stable
      Regex.match?(~r/####\s+Experimental\s*\{:\s*\.warning\}/, text) -> :experimental
      true -> :unclassified
    end
  end

  @doc false
  def exported_functions(module) do
    module
    |> function_exports()
    |> reject_builtin_exports()
    |> Enum.map(&format_export/1)
    |> Enum.sort()
  end

  @doc false
  def exported_macros(module) do
    module
    |> macro_exports()
    |> reject_builtin_exports()
    |> Enum.map(&format_export/1)
    |> Enum.sort()
  end

  @doc false
  def callbacks(module) do
    module
    |> docs_callbacks()
    |> Enum.map(&format_export/1)
    |> Enum.sort()
  end

  @doc false
  def struct_keys(module) do
    if function_exported?(module, :__struct__, 0) do
      module
      |> apply(:__struct__, [])
      |> Map.keys()
      |> Enum.reject(&(&1 == :__struct__))
      |> Enum.map(&to_string/1)
      |> Enum.sort()
    else
      []
    end
  end

  defp function_exports(module), do: module.__info__(:functions)
  defp macro_exports(module), do: module.__info__(:macros)

  defp docs_callbacks(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        Enum.flat_map(docs, fn
          {{kind, name, arity}, _, _, _, _} when kind in [:callback, :macrocallback] ->
            [{name, arity}]

          _other ->
            []
        end)

      _other ->
        []
    end
  end

  defp reject_builtin_exports(exports) do
    Enum.reject(exports, fn {name, _arity} ->
      name in [:__info__, :module_info]
    end)
  end

  defp format_export({name, arity}), do: "#{name}/#{arity}"
end
