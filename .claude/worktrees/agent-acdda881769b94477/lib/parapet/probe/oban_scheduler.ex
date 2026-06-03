if Code.ensure_loaded?(Oban.Worker) do
  defmodule Parapet.Probe.ObanScheduler do
    @moduledoc """
    Optional Oban worker for scheduling synthetic probes without retries.

    > #### Experimental {: .warning}
    >
    > This module is **experimental** in v1.x. Its API may change in a minor release with a
    > single-version notice in CHANGELOG.md. See
    > [Stability & Deprecation Policy](stability.html) for details.
    """
    use Oban.Worker, max_attempts: 1

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"probe" => probe_str}}) do
      with {:ok, module} <- resolve_probe(probe_str),
           true <- probe_valid?(module) do
        apply(module, :execute, [])
      else
        _ -> {:error, :invalid_probe}
      end
    end

    defp resolve_probe(probe_str) do
      try do
        module = String.to_existing_atom(probe_str)
        Code.ensure_loaded?(module)
        {:ok, module}
      rescue
        ArgumentError -> {:error, :not_found}
      end
    end

    defp probe_valid?(module) do
      function_exported?(module, :execute, 0)
    end
  end
end
