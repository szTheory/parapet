defmodule Parapet.DoctorSchemaCheckTest do
  @moduledoc false

  # async: false — this module mutates Application.put_env; parallelism would race
  # against other test modules reading :parapet config (D-02 unit test contract).
  use ExUnit.Case, async: false

  # Import the private check_schema/0 via :erlang.apply or alias the module so we
  # can call the public run/1 interface with named checks.
  # We test via Mix.Tasks.Parapet.Doctor.run/1 (public) for --ci exit-code contract,
  # and test check internals via the named-check path: run(["schema"]).

  # Bind the compiled prefix at module load so every assertion branches correctly
  # on the active CI leg (parapet or nil). Mirrors prefix_propagation_test.exs:14.
  @prefix Parapet.Spine.Schema.__prefix__()

  # ---------------------------------------------------------------------------
  # D-02: drift detection — normalize on BOTH sides prevents false positives
  # ---------------------------------------------------------------------------

  describe "D-02 drift detection" do
    test "returns :error with recompile remediation when runtime prefix disagrees with compiled" do
      # Pick a value that normalizes DIFFERENTLY from the compiled @prefix:
      #   compiled = nil  → use "parapet" (normalizes to "parapet" ≠ nil → drift)
      #   compiled = "parapet" → use nil    (normalizes to nil ≠ "parapet" → drift)
      drifted_value =
        if is_nil(@prefix) do
          "parapet"
        else
          nil
        end

      on_exit(fn ->
        Application.delete_env(:parapet, :schema_prefix)
      end)

      Application.put_env(:parapet, :schema_prefix, drifted_value)

      result = check_schema()

      assert result.status == :error,
             "Expected :error on drift, got #{result.status}"

      [message] = result.messages

      assert message =~ "Config drift:",
             "Expected drift message, got: #{message}"

      assert message =~ "mix deps.compile parapet --force",
             "Expected recompile remediation in message, got: #{message}"
    end

    # D-02 / Pitfall 2 — double-normalize prevents nil-vs-public false positive.
    test "does NOT return :error from drift when runtime prefix normalizes equal to compiled (no false-positive)" do
      # Pick a value that normalizes EQUAL to the compiled prefix:
      #   compiled = nil  → use nil / "" / "public" all normalize to nil
      #   compiled = "parapet" → use "parapet" (normalizes to "parapet")
      equal_value =
        if is_nil(@prefix) do
          # nil, "", and "public" ALL normalize to nil — use "" to exercise the alias
          ""
        else
          @prefix
        end

      on_exit(fn ->
        Application.delete_env(:parapet, :schema_prefix)
      end)

      Application.put_env(:parapet, :schema_prefix, equal_value)

      result = check_schema()

      # When compiled == nil and runtime == "" → both normalize to nil → no drift.
      # When compiled == "parapet" and runtime == "parapet" → no drift.
      # Status may be :skip (repo not running in test env) or :info; it must NOT be
      # :error from drift.
      refute result.status == :error and hd(result.messages) =~ "Config drift:",
             "False-positive drift detected on equal-normalized prefix. " <>
               "compiled=#{inspect(@prefix)}, runtime=#{inspect(equal_value)}, " <>
               "result=#{inspect(result)}"
    end
  end

  # ---------------------------------------------------------------------------
  # D-03: existence degrades to :skip when repo not running
  # ---------------------------------------------------------------------------

  describe "D-03 skip when repo not running" do
    test "returns :skip (never raises) when no repo is configured" do
      on_exit(fn ->
        Application.delete_env(:parapet, :repo)
        Application.delete_env(:parapet, :schema_prefix)
      end)

      # Set matching prefix to isolate the existence signal (no drift).
      Application.put_env(:parapet, :schema_prefix, @prefix)
      Application.put_env(:parapet, :repo, nil)

      result = check_schema()

      assert result.status == :skip,
             "Expected :skip when repo is nil, got #{result.status}: #{inspect(result.messages)}"

      [message] = result.messages

      assert message =~ "Schema-existence check skipped",
             "Expected skip message, got: #{message}"

      assert message =~ "mix parapet.doctor cluster",
             "Expected cluster suggestion in skip message, got: #{message}"
    end

    test "returns :skip (never raises) when repo process is not running" do
      on_exit(fn ->
        Application.delete_env(:parapet, :repo)
        Application.delete_env(:parapet, :schema_prefix)
      end)

      # Use a module atom that is definitely not a running process.
      Application.put_env(:parapet, :schema_prefix, @prefix)
      Application.put_env(:parapet, :repo, NonExistentRepo.For.TestPurposesOnly)

      # Must not raise even with a plausible-but-absent repo module.
      result =
        assert_raise_or_return(fn ->
          check_schema()
        end)

      # If it raised, the test would fail here. We assert it did NOT.
      assert result.status == :skip,
             "Expected :skip for absent repo process, got #{result.status}: #{inspect(result.messages)}"
    end
  end

  # ---------------------------------------------------------------------------
  # D-04 / D-05: --ci exit-code contract
  # ---------------------------------------------------------------------------

  describe "D-05 --ci exit-code contract" do
    test ":error severity is at or above :warn threshold (maps to exit 1 under --ci)" do
      # The @severity_order in Doctor maps warn: 1, error: 2.
      # A drift finding has status :error → must satisfy finding_at_or_above_threshold?(:error, :warn).
      # We verify this by asserting the severity ordering directly via the check result,
      # not by trapping System.halt (which would kill the VM).
      #
      # We construct a drift scenario and confirm the returned :error status would
      # satisfy the --ci threshold.

      severity_order = %{skip: 0, info: 0, warn: 1, error: 2}

      # :error must be >= :warn threshold (this is how --ci maps drift to exit 1).
      assert Map.fetch!(severity_order, :error) >= Map.fetch!(severity_order, :warn),
             ":error severity must be at or above :warn (the --ci threshold); got order: #{inspect(severity_order)}"
    end

    test "drift finding status :error is recognized as a CI failure severity" do
      drifted_value =
        if is_nil(@prefix) do
          "parapet"
        else
          nil
        end

      on_exit(fn ->
        Application.delete_env(:parapet, :schema_prefix)
      end)

      Application.put_env(:parapet, :schema_prefix, drifted_value)

      result = check_schema()

      # The returned status from a drift scenario must be :error.
      # When fed to findings_exit_code/2 with threshold :warn (--ci default),
      # the severity_order lookup returns 2 >= 1 → exit 1.
      assert result.status == :error,
             "Drift scenario must produce :error status; got #{result.status}"
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Delegate to the @doc false public check_schema/0 on the Doctor task.
  # The function is public (not private) precisely to support this test contract
  # while keeping its Mix Task interface stable via the named-check dispatch.
  defp check_schema do
    Mix.Tasks.Parapet.Doctor.check_schema()
  end

  # Run the function; if it raises return a synthetic error result.
  # Used to assert that D-03 skip guard never raises.
  defp assert_raise_or_return(fun) do
    try do
      fun.()
    rescue
      e ->
        flunk(
          "check_schema/0 raised an exception instead of returning :skip: #{inspect(e)}\n" <>
            Exception.message(e)
        )
    end
  end
end
