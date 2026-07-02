defmodule Parapet.TestSupport.ConcurrencyCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Parapet.TestSupport.{ConcurrencyBootstrap, ConcurrencyRepo}

  using do
    quote do
      import Parapet.TestSupport.ConcurrencyCase,
        only: [
          unboxed_run: 1,
          allow: 2,
          assert_eventually: 2,
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

  @doc false
  # assert_eventually(fun, opts \\ [])
  #
  # Re-invokes fun on a constant interval until it returns a truthy value or
  # stops raising ExUnit.AssertionError. On success, returns the truthy value
  # (so callers can bind it). On timeout, re-raises the last real assertion
  # diff verbatim — never a generic "timed out" message (the #1 prior-art
  # footgun in hex libs and blog patterns).
  #
  # opts:
  #   :timeout  — total ms budget (default 1_000)
  #   :interval — constant poll interval in ms, no backoff (default 25)
  #   :message  — optional string prefix on the falsy-timeout failure message
  #
  # CATCH ONLY ExUnit.AssertionError (D-14): a MatchError, DBConnection crash,
  # or any other exception raised by fun is a real bug and propagates immediately.
  #
  # Sandbox contract (D-15, documented, not enforced): poll from the test
  # process that owns the sandbox connection; a spawned poller needs allow/2.
  # Use assert_eventually only for no-message DB/state-projection settle cases;
  # assert_receive remains the idiom for message-passing waits.
  def assert_eventually(fun, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 1_000)
    interval = Keyword.get(opts, :interval, 25)
    message = Keyword.get(opts, :message, nil)
    start = System.monotonic_time(:millisecond)
    deadline = start + timeout

    do_assert_eventually(fun, deadline, interval, message, start, nil, nil)
  end

  defp do_assert_eventually(fun, deadline, interval, message, start, last_error, last_falsy) do
    try do
      result = fun.()

      if result do
        result
      else
        if System.monotonic_time(:millisecond) >= deadline do
          elapsed = System.monotonic_time(:millisecond) - start
          prefix = if message, do: "#{message}\n", else: ""

          raise ExUnit.AssertionError,
            message:
              "#{prefix}assert_eventually timed out after #{elapsed}ms. " <>
                "Last value: #{inspect(last_falsy || result)}."
        else
          Process.sleep(interval)
          do_assert_eventually(fun, deadline, interval, message, start, nil, result)
        end
      end
    rescue
      err in ExUnit.AssertionError ->
        st = __STACKTRACE__

        if System.monotonic_time(:millisecond) >= deadline do
          reraise err, st
        else
          Process.sleep(interval)
          do_assert_eventually(fun, deadline, interval, message, start, {err, st}, last_falsy)
        end
    end
  end

  def start_distributed_node_for_peer_canary do
    cond do
      Node.alive?() ->
        {:ok, false}

      true ->
        name = :"parapet_executor_smoke_#{System.unique_integer([:positive])}"

        case Node.start(name, name_domain: :shortnames) do
          {:ok, _pid} -> {:ok, true}
          {:error, {{:already_started, _pid}, _details}} -> {:ok, false}
          {:error, {:already_started, _pid}} -> {:ok, false}
          {:error, reason} -> normalize_distribution_start_error(reason)
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
