defmodule Parapet.TestSupport.ConcurrencyCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Parapet.TestSupport.{ConcurrencyBootstrap, ConcurrencyRepo}

  using do
    quote do
      import Parapet.TestSupport.ConcurrencyCase,
        only: [
          unboxed_run: 1,
          allow: 2,
          start_distributed_node_for_peer_canary: 0,
          stop_distributed_node_for_peer_canary: 1
        ]

      alias Parapet.TestSupport.{ConcurrencyBootstrap, ConcurrencyRepo}
    end
  end

  setup tags do
    Application.put_env(:parapet, :repo, ConcurrencyRepo)

    unless tags[:unboxed] do
      :ok = Sandbox.checkout(ConcurrencyRepo)
      ConcurrencyBootstrap.reset!()
    end

    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
    end)

    :ok
  end

  def allow(owner, pid), do: Sandbox.allow(ConcurrencyRepo, owner, pid)

  def unboxed_run(fun), do: Sandbox.unboxed_run(ConcurrencyRepo, fun)

  def start_distributed_node_for_peer_canary do
    cond do
      Node.alive?() ->
        {:ok, false}

      true ->
        name = :"parapet_executor_smoke_#{System.unique_integer([:positive])}"

        case Node.start(name, :shortnames) do
          {:ok, _pid} -> {:ok, true}
          {:error, {{:already_started, _pid}, _details}} -> {:ok, false}
          {:error, {:already_started, _pid}} -> {:ok, false}
          {:error, reason} -> normalize_distribution_start_error(reason)
          other -> normalize_distribution_start_error(other)
        end
    end
  end

  def stop_distributed_node_for_peer_canary(true), do: :net_kernel.stop()
  def stop_distributed_node_for_peer_canary(false), do: :ok

  defp normalize_distribution_start_error(reason) do
    if distribution_unavailable_reason?(reason) do
      distribution_unavailable(reason)
    else
      raise "unexpected distributed node startup failure: #{inspect(reason)}"
    end
  end

  defp distribution_unavailable(reason) do
    details =
      reason
      |> inspect()
      |> String.trim()

    {:skip,
     "peer-node canary was skipped because distributed Erlang is unavailable in this environment. " <>
       "The DB-backed contention suite remains the closure-grade proof for SCALE-02. " <>
       "Distribution startup details: #{details}"}
  end

  defp distribution_unavailable_reason?(value) when is_tuple(value) do
    value
    |> Tuple.to_list()
    |> Enum.any?(&distribution_unavailable_reason?/1)
  end

  defp distribution_unavailable_reason?(value) when is_list(value) do
    Enum.any?(value, &distribution_unavailable_reason?/1)
  end

  defp distribution_unavailable_reason?(:nodistribution), do: true
  defp distribution_unavailable_reason?(:econnrefused), do: true
  defp distribution_unavailable_reason?(:eperm), do: true
  defp distribution_unavailable_reason?(:eaddrnotavail), do: true
  defp distribution_unavailable_reason?(value) when is_atom(value), do: false

  defp distribution_unavailable_reason?(value) when is_binary(value) do
    String.contains?(value, "nodistribution") or String.contains?(value, "econnrefused")
  end

  defp distribution_unavailable_reason?(_value), do: false
end
