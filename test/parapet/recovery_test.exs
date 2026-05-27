# Fixture host modules for the sync sweep — inline in the test file per D-14 (no test/support/).
# Each uses Parapet.Recovery (not @behaviour directly) to exercise the __using__/1 ergonomic
# path spelled out in RCV-01.

defmodule Parapet.RecoveryTest.FixtureRetryAsync do
  use Parapet.Recovery
  def id, do: :retry_async_item
  def label, do: "Retry Async (Fixture)"
  def preview(_incident, _step), do: {:ok, %{}}
  def execute(_incident, _target_refs), do: {:ok, %{}}
end

defmodule Parapet.RecoveryTest.FixtureRequeueDLQ do
  use Parapet.Recovery
  def id, do: :requeue_dead_letter
  def label, do: "Requeue Dead Letter (Fixture)"
  def preview(_incident, _step), do: {:ok, %{}}
  def execute(_incident, _target_refs), do: {:ok, %{}}
end

defmodule Parapet.RecoveryTest.FixtureRevertFeatureFlag do
  use Parapet.Recovery
  def id, do: :revert_feature_flag
  def label, do: "Revert Feature Flag (Fixture)"
  def preview(_incident, _step), do: {:ok, %{}}
  def execute(_incident, _target_refs), do: {:ok, %{}}
end

defmodule Parapet.RecoveryTest.FixtureDisableMetricLabel do
  use Parapet.Recovery
  def id, do: :disable_metric_label
  def label, do: "Disable Metric Label (Fixture)"
  def preview(_incident, _step), do: {:ok, %{}}
  def execute(_incident, _target_refs), do: {:ok, %{}}
end

defmodule Parapet.RecoveryTest.FixtureInvalidId do
  use Parapet.Recovery
  def id, do: :not_in_allowlist
  def label, do: "Invalid (Fixture)"
  def preview(_incident, _step), do: {:ok, %{}}
  def execute(_incident, _target_refs), do: {:ok, %{}}
end

# ---------------------------------------------------------------------------
# Sync sweep — covers Phase 24 success criteria #1, #2, #3.
#
# Uses async: false because setup resets Agent state via Agent.update/2.
# Running state-reset tests concurrently would race: one test's reset would
# wipe another test's registered capability mid-assertion.
# ---------------------------------------------------------------------------

defmodule Parapet.RecoveryTest do
  use ExUnit.Case, async: false

  alias Parapet.{Capabilities, Recovery}

  # Verbatim setup from test/parapet/capabilities_test.exs:6-17 (per D-14 / Pattern 6).
  # start_supervised/1 is idempotent: if the Agent is already running (it is supervised
  # at boot), the :already_started branch resets state to a clean %{recovery: %{}}.
  setup do
    case start_supervised(Capabilities) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        Agent.update(Capabilities, fn _ -> %{recovery: %{}} end)
        :ok
    end

    :ok
  end

  describe "attach/1" do
    # SC #1 — attach/1 registers a loaded fixture host module into Capabilities.
    test "registers a loaded fixture host module" do
      assert {:ok, [:retry_async_item]} =
               Recovery.attach([Parapet.RecoveryTest.FixtureRetryAsync])

      cap = Capabilities.get_recovery(:retry_async_item)
      assert cap != nil
      assert cap.id == :retry_async_item
      assert cap.name == "Retry Async (Fixture)"
      assert is_function(cap.preview, 2)
      assert is_function(cap.execute, 2)
    end

    # SC #2 (skip side) — attach/1 silently skips a module that is not loaded.
    test "silently skips an unloaded module" do
      assert {:ok, []} = Recovery.attach([NonExistent.Module])
    end

    # SC #2 (mixed) — attach/1 skips unloaded modules but registers loaded ones.
    test "skips unloaded modules but registers loaded ones in a mixed list" do
      assert {:ok, [:requeue_dead_letter]} =
               Recovery.attach([NonExistent.Module, Parapet.RecoveryTest.FixtureRequeueDLQ])

      assert Capabilities.get_recovery(:requeue_dead_letter) != nil
    end

    # SC #3 (widening side) — the new :revert_feature_flag atom is accepted by
    # register_recovery/2 via attach/1 (D-09 allowlist widening).
    test "accepts the new :revert_feature_flag allowlist atom" do
      assert {:ok, [:revert_feature_flag]} =
               Recovery.attach([Parapet.RecoveryTest.FixtureRevertFeatureFlag])

      cap = Capabilities.get_recovery(:revert_feature_flag)
      assert cap != nil
      assert cap.id == :revert_feature_flag
    end

    # SC #3 (widening side) — the new :disable_metric_label atom is accepted by
    # register_recovery/2 via attach/1 (D-09 allowlist widening).
    test "accepts the new :disable_metric_label allowlist atom" do
      assert {:ok, [:disable_metric_label]} =
               Recovery.attach([Parapet.RecoveryTest.FixtureDisableMetricLabel])

      cap = Capabilities.get_recovery(:disable_metric_label)
      assert cap != nil
      assert cap.id == :disable_metric_label
    end

    # SC #3 (rejection side) — attach/1 raises ArgumentError when a fixture's id/0
    # returns an atom outside the 5-atom allowlist. The raise flows through attach/1
    # → Capabilities.register_recovery/2 (not tested via register_recovery/2 directly,
    # so the full attach/1 delegation path is exercised).
    test "raises ArgumentError when fixture id/0 returns an out-of-allowlist atom" do
      assert_raise ArgumentError, ~r/Invalid recovery capability id/, fn ->
        Recovery.attach([Parapet.RecoveryTest.FixtureInvalidId])
      end
    end

    # Edge case — empty list returns {:ok, []} without error (D-08).
    test "returns {:ok, []} when given an empty list" do
      assert {:ok, []} = Recovery.attach([])
    end
  end
end

# ---------------------------------------------------------------------------
# Async sweep — covers Phase 24 success criterion #4.
#
# 100 async tests parameterized cyclically over the 5 allowlisted atoms.
#
# Why this is safe with a shared supervised Agent (DO NOT REWRITE TO USE A SANDBOX):
#   - Parapet.Capabilities is a single named Agent supervised at boot
#     (lib/parapet/internal/application.ex). It is NOT reset per test.
#   - Agent.update serializes all writes through the Agent's mailbox.
#   - The :recovery map is keyed by capability id; per-key put_in means
#     concurrent writers on DISTINCT keys do not corrupt each other, and
#     concurrent writers on the SAME key get last-writer-wins.
#   - Each test reads ONLY the row it just wrote (via get_recovery/1).
#     NEVER assert on capabilities(:recovery) list cardinality — that races.
#   - This is NOT the v0.10 SLO Pitfall 13 mistake (Application env indirection);
#     that mistake mutated shared atomic flags. Per-key map cells with
#     last-writer-wins-per-cell are race-free for the assertion we make.
#
# D-13 option (b): parameterize over all 5 atoms cyclically — preferred over
# option (a) (single atom + varied names) because it also exercises the two
# new allowlist atoms (:revert_feature_flag, :disable_metric_label) under
# concurrent contention, which is the strongest SC #4 proof.
# ---------------------------------------------------------------------------

defmodule Parapet.RecoveryAsyncSweepTest do
  use ExUnit.Case, async: true

  alias Parapet.Capabilities

  @allowlisted_ids [
    :retry_async_item,
    :requeue_dead_letter,
    :request_manual_provider_check,
    :revert_feature_flag,
    :disable_metric_label
  ]

  for n <- 1..100 do
    test "async write #{n} is isolated per key" do
      n = unquote(n)
      id = Enum.at(@allowlisted_ids, rem(n, 5))
      name = "async-fixture-#{n}"

      preview_fun = fn _incident, _step -> {:ok, %{n: n}} end
      execute_fun = fn _incident, _target_refs -> {:ok, %{n: n}} end

      :ok =
        Capabilities.register_recovery(id,
          name: name,
          preview: preview_fun,
          execute: execute_fun
        )

      cap = Capabilities.get_recovery(id)
      assert cap != nil

      # Read-only-on-just-written-key: do NOT assert cap.name == name,
      # because another async test cycling the same id may have written
      # after us. The contract is just: the row exists with the right id.
      assert cap.id == id
      assert is_function(cap.preview, 2)
      assert is_function(cap.execute, 2)
    end
  end
end
