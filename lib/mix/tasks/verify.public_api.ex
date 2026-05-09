defmodule Mix.Tasks.Verify.PublicApi do
  @moduledoc """
  Verifies that all public API modules have documentation and generate a manifest.
  """
  use Mix.Task

  @shortdoc "Verifies public API module documentation"

  @impl Mix.Task
  def run(_args) do
    # Ensure application is compiled and loaded
    Mix.Task.run("compile")
    Application.load(:parapet)

    {:ok, modules} = :application.get_key(:parapet, :modules)

    manifest =
      modules
      |> Enum.filter(&is_public_api_module?/1)
      |> Enum.map(&check_module_docs/1)
      |> Enum.sort_by(& &1.module)

    # Encode to JSON if Jason is available, otherwise use inspect
    output =
      if Code.ensure_loaded?(Jason) do
        Jason.encode!(manifest, pretty: true)
      else
        inspect(manifest, pretty: true, limit: :infinity)
      end

    IO.puts(output)

    if Enum.any?(manifest, fn m -> not m.has_docs end) do
      IO.puts(:stderr, "Error: One or more public API modules are missing documentation.")
      System.halt(1)
    end
  end

  defp is_public_api_module?(module) do
    name = inspect(module)

    (String.starts_with?(name, "Parapet.") or name == "Parapet") and
      not String.starts_with?(name, "Parapet.Internal.")
  end

  defp check_module_docs(module) do
    has_docs =
      case Code.fetch_docs(module) do
        {:docs_v1, _, :elixir, _, :hidden, _, _} -> false
        {:docs_v1, _, :elixir, "none", _, _, _} -> false
        {:docs_v1, _, :elixir, :none, _, _, _} -> false
        {:docs_v1, _, :elixir, _, _, _, _} -> true
        {:error, _} -> false
        _ -> false
      end

    %{
      module: inspect(module),
      has_docs: has_docs
    }
  end
end
