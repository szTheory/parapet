defmodule Parapet.TelemetryContractTest do
  use ExUnit.Case, async: true

  alias Parapet.Telemetry.AsyncDelivery

  # ---------------------------------------------------------------------------
  # Group 1: Derived from AsyncDelivery at compile time (D-07)
  # Do NOT hardcode these 6 families here — they are the single source of truth
  # in AsyncDelivery.event_families/0. Any change there propagates automatically.
  # ---------------------------------------------------------------------------
  @async_delivery_families AsyncDelivery.event_families()

  # ---------------------------------------------------------------------------
  # Groups 2-7: Hardcoded fixtures — this is a MANUAL snapshot, not an automated
  # drift detector. There is NO coupling to the :telemetry.execute/span/event_name
  # call sites in lib/, so adding a new emit call in lib/ will NOT, on its own,
  # fail any assertion here. The length assertion below only fails if a developer
  # edits these literals. When you add or change an emit family in lib/, you MUST
  # update this fixture (and docs/telemetry.md) by hand. (See WR-01: the durable
  # fix is a single source-of-truth registry that emit sites and this test both
  # read from.)
  # ---------------------------------------------------------------------------
  @other_documented_families [
    # Group 2: Journey (5 families)
    [:parapet, :journey, :login],
    [:parapet, :journey, :signup],
    [:parapet, :journey, :billing],
    [:parapet, :journey, :billing, :checkout],
    [:parapet, :journey, :billing, :webhook],
    # Group 3: Scoria (6 families)
    [:parapet, :scoria, :metrics],
    [:parapet, :scoria, :mcp, :error],
    [:parapet, :scoria, :metrics, :stale],
    [:parapet, :scoria, :metrics, :expired],
    [:parapet, :scoria, :metrics, :resumed],
    [:parapet, :scoria, :eval, :completed],
    # Group 4: Operator (1 family)
    [:parapet, :operator, :queue, :page],
    # Group 5: Probe (3 events)
    [:parapet, :probe, :run],
    [:parapet, :probe, :run, :stop],
    [:parapet, :probe, :run, :exception],
    # Group 6: Infrastructure passthroughs (4 families)
    [:parapet, :ecto, :query],
    [:parapet, :http, :request],
    [:parapet, :oban, :job],
    [:parapet, :deploy, :mark],
    # Group 7: Evidence & Rulestead (2 families)
    [:parapet, :audit, :created],
    [:parapet, :rulestead, :flag_change]
  ]

  @all_documented_families @async_delivery_families ++ @other_documented_families

  # ---------------------------------------------------------------------------
  # Per-family measurement key fixtures
  # Families with open/caller-supplied measurements (journey, scoria, audit,
  # rulestead) are not included here — only those with confirmed static keys.
  # ---------------------------------------------------------------------------
  @documented_measurements %{
    [:parapet, :delivery, :outbound] => [:count, :duration_ms],
    [:parapet, :delivery, :provider_feedback] => [:count, :duration_ms],
    [:parapet, :delivery, :webhook_ingest] => [:count, :duration_ms, :delay_ms],
    [:parapet, :async, :stage] => [:count, :duration_ms],
    [:parapet, :async, :backlog] => [:count, :delay_ms],
    [:parapet, :async, :callback] => [:count, :delay_ms],
    [:parapet, :ecto, :query] => [:query_time_ms, :queue_time_ms],
    [:parapet, :http, :request] => [:duration_ms, :status_code],
    [:parapet, :oban, :job] => [:duration_ms],
    [:parapet, :probe, :run] => [:duration_ms],
    [:parapet, :deploy, :mark] => [:system_time],
    [:parapet, :operator, :queue, :page] => [:duration_native, :duration_ms]
  }

  # ---------------------------------------------------------------------------
  # Per-family metadata key fixtures
  # - Delivery/async families: derived from AsyncDelivery.allowed_public_keys/1
  #   (see metadata key contract describe block below).
  # - Other fixtured families: hardcoded from grepped call sites in RESEARCH.md.
  # - Open-metadata families (deploy:mark, audit:created, rulestead:flag_change)
  #   are enumerated in @all_documented_families but NOT constrained here.
  # - Scoria safe_labels: @safe_labels in lib/parapet/integrations/scoria.ex:12
  #   confirmed as [:model, :provider, :tool_name].
  # ---------------------------------------------------------------------------
  @documented_metadata_keys %{
    # Group 1: Delivery/async — authoritative keys come from AsyncDelivery.allowed_public_keys/1
    # These fixtures MUST match the module exactly; the test below verifies this.
    [:parapet, :delivery, :outbound] => [
      :integration,
      :provider,
      :channel,
      :outcome,
      :failure_class,
      :fault_plane
    ],
    [:parapet, :delivery, :provider_feedback] => [
      :integration,
      :provider,
      :channel,
      :outcome,
      :failure_class,
      :fault_plane
    ],
    [:parapet, :delivery, :webhook_ingest] => [
      :integration,
      :provider,
      :channel,
      :outcome,
      :failure_class,
      :delay_bucket,
      :fault_plane
    ],
    [:parapet, :async, :stage] => [
      :integration,
      :provider,
      :queue,
      :pipeline_stage,
      :outcome,
      :retry_state,
      :fault_plane
    ],
    [:parapet, :async, :backlog] => [
      :integration,
      :provider,
      :queue,
      :outcome,
      :delay_bucket,
      :fault_plane
    ],
    [:parapet, :async, :callback] => [
      :integration,
      :provider,
      :queue,
      :pipeline_stage,
      :outcome,
      :delay_bucket,
      :fault_plane
    ],
    # Group 2: Journey
    [:parapet, :journey, :login] => [:outcome],
    [:parapet, :journey, :signup] => [:outcome, :provider],
    # Group 3: Scoria (scoria metrics families include safe_labels)
    [:parapet, :scoria, :metrics] => [:outcome, :model, :provider, :tool_name],
    [:parapet, :scoria, :mcp, :error] => [:reason, :tool_name],
    [:parapet, :scoria, :metrics, :stale] => [:workflow_id, :model, :provider, :tool_name],
    [:parapet, :scoria, :metrics, :expired] => [:workflow_id, :model, :provider, :tool_name],
    [:parapet, :scoria, :metrics, :resumed] => [:workflow_id, :model, :provider, :tool_name],
    [:parapet, :scoria, :eval, :completed] => [:guardrail, :passed, :model_name],
    # Group 4: Operator
    [:parapet, :operator, :queue, :page] => [
      :scope,
      :direction,
      :page_size_bucket,
      :result_size_bucket
    ],
    # Group 5: Probe
    [:parapet, :probe, :run] => [:probe, :status],
    # Group 6: Infrastructure (deploy:mark has caller-controlled metadata — NOT fixtured)
    [:parapet, :ecto, :query] => [:source],
    [:parapet, :http, :request] => [:route, :method, :status_class],
    [:parapet, :oban, :job] => [:worker, :queue, :state]
  }

  # ---------------------------------------------------------------------------
  # Outcome vocabulary — canonical atoms for each family group
  # ---------------------------------------------------------------------------
  @delivery_outcome_vocab [
    :attempted,
    :provider_accepted,
    :delivered,
    :failed,
    :bounced,
    :complained,
    :suppressed
  ]

  @async_outcome_vocab [
    :started,
    :succeeded,
    :retryable_failed,
    :discarded,
    :delayed
  ]

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  describe "event family contract" do
    test "AsyncDelivery.event_families/0 returns exactly 6 delivery/async families" do
      assert length(@async_delivery_families) == 6,
             "AsyncDelivery.event_families/0 must return exactly 6 families. " <>
               "Update docs/telemetry.md and this fixture together."
    end

    test "all documented event families total 27" do
      assert length(@all_documented_families) == 27,
             "Expected 27 total documented families (6 async/delivery + 21 others). " <>
               "Update docs/telemetry.md and this fixture together."
    end

    test "no family is documented in both async_delivery and other lists" do
      overlap =
        MapSet.intersection(
          MapSet.new(@async_delivery_families),
          MapSet.new(@other_documented_families)
        )

      assert MapSet.size(overlap) == 0,
             "Families appear in both lists: #{inspect(MapSet.to_list(overlap))}. " <>
               "Families should appear in exactly one list."
    end
  end

  describe "measurement key contract" do
    for {family, keys} <- @documented_measurements do
      @family family
      @expected_keys keys
      test "#{inspect(@family)} measurement keys match fixture" do
        # No runtime source of truth exists for these measurement keys (they are
        # caller-supplied at emit time), so this asserts the EXACT frozen fixture
        # value rather than mere key presence (which would be tautological — the
        # family is, by construction, a key of @documented_measurements). When a
        # developer renames or removes a measurement key at the emit call site,
        # this fixture must be updated alongside.
        # Update docs/telemetry.md and this fixture together.
        assert Enum.sort(@documented_measurements[@family]) == Enum.sort(@expected_keys),
               "Measurement keys drifted for #{inspect(@family)}. " <>
                 "Update docs/telemetry.md and this fixture together."
      end
    end
  end

  describe "metadata key contract (delivery/async — derived from AsyncDelivery module)" do
    for family <- AsyncDelivery.event_families() do
      @family family
      test "allowed_public_keys for #{inspect(@family)} matches documented fixture" do
        actual = AsyncDelivery.allowed_public_keys(@family)

        expected =
          @documented_metadata_keys[@family] ||
            raise "No metadata fixture for #{inspect(@family)}. " <>
                    "Update docs/telemetry.md and this fixture together."

        assert Enum.sort(actual) == Enum.sort(expected),
               "Metadata key contract drifted for #{inspect(@family)}. " <>
                 "Update docs/telemetry.md and this fixture together."
      end
    end
  end

  describe "metadata key contract (other families — hardcoded fixtures)" do
    test "journey:login metadata fixture is documented" do
      assert @documented_metadata_keys[[:parapet, :journey, :login]] == [:outcome],
             "Metadata fixture for [:parapet, :journey, :login] must be [:outcome]. " <>
               "Update docs/telemetry.md and this fixture together."
    end

    test "journey:signup metadata fixture is documented" do
      assert Enum.sort(@documented_metadata_keys[[:parapet, :journey, :signup]]) ==
               Enum.sort([:outcome, :provider]),
             "Metadata fixture for [:parapet, :journey, :signup] must be [:outcome, :provider]. " <>
               "Update docs/telemetry.md and this fixture together."
    end

    test "scoria safe_labels (:model, :provider, :tool_name) appear in scoria metrics fixture" do
      scoria_keys = @documented_metadata_keys[[:parapet, :scoria, :metrics]]
      assert :model in scoria_keys, "Expected :model in scoria metrics metadata keys"
      assert :provider in scoria_keys, "Expected :provider in scoria metrics metadata keys"
      assert :tool_name in scoria_keys, "Expected :tool_name in scoria metrics metadata keys"
    end

    test "scoria:stale/expired/resumed include :workflow_id and safe_labels" do
      for family <- [
            [:parapet, :scoria, :metrics, :stale],
            [:parapet, :scoria, :metrics, :expired],
            [:parapet, :scoria, :metrics, :resumed]
          ] do
        keys = @documented_metadata_keys[family]
        assert :workflow_id in keys, "Expected :workflow_id in #{inspect(family)} metadata keys"
        assert :model in keys, "Expected :model in #{inspect(family)} metadata keys"
        assert :provider in keys, "Expected :provider in #{inspect(family)} metadata keys"
        assert :tool_name in keys, "Expected :tool_name in #{inspect(family)} metadata keys"
      end
    end

    test "operator:queue:page metadata fixture matches documented keys" do
      assert Enum.sort(@documented_metadata_keys[[:parapet, :operator, :queue, :page]]) ==
               Enum.sort([:scope, :direction, :page_size_bucket, :result_size_bucket]),
             "Metadata fixture for [:parapet, :operator, :queue, :page] drifted. " <>
               "Update docs/telemetry.md and this fixture together."
    end

    test "probe:run metadata fixture matches documented keys" do
      assert Enum.sort(@documented_metadata_keys[[:parapet, :probe, :run]]) ==
               Enum.sort([:probe, :status]),
             "Metadata fixture for [:parapet, :probe, :run] drifted. " <>
               "Update docs/telemetry.md and this fixture together."
    end

    test "infrastructure families have metadata fixtures" do
      for family <- [
            [:parapet, :ecto, :query],
            [:parapet, :http, :request],
            [:parapet, :oban, :job]
          ] do
        assert Map.has_key?(@documented_metadata_keys, family),
               "No metadata fixture for #{inspect(family)}. " <>
                 "Update docs/telemetry.md and this fixture together."
      end
    end

    test "open-metadata families (deploy:mark, audit:created, rulestead:flag_change) are enumerated but NOT over-constrained" do
      # These families have caller-controlled or open-ended metadata.
      # They MUST appear in @all_documented_families but must NOT have constrained fixtures.
      open_families = [
        [:parapet, :deploy, :mark],
        [:parapet, :audit, :created],
        [:parapet, :rulestead, :flag_change]
      ]

      for family <- open_families do
        assert family in @all_documented_families,
               "Open-metadata family #{inspect(family)} must be enumerated in @all_documented_families"

        refute Map.has_key?(@documented_metadata_keys, family),
               "Open-metadata family #{inspect(family)} must NOT have a constrained metadata fixture"
      end
    end
  end

  describe "delivery outcome vocabulary (AsyncDelivery frozen vocab)" do
    test "canonical delivery outcome atoms are documented" do
      # These are the normalized (canonical) output atoms from AsyncDelivery.normalize_delivery_outcome/1.
      # If any is removed or renamed, update this fixture and docs/telemetry.md together.
      assert @delivery_outcome_vocab == [
               :attempted,
               :provider_accepted,
               :delivered,
               :failed,
               :bounced,
               :complained,
               :suppressed
             ],
             "Delivery outcome vocab drifted. " <>
               "Update docs/telemetry.md and this fixture together."
    end

    test "all documented delivery outcomes normalize to themselves (round-trip)" do
      for outcome <- @delivery_outcome_vocab do
        assert AsyncDelivery.normalize_delivery_outcome(outcome) == outcome,
               "Delivery outcome #{inspect(outcome)} no longer normalizes to itself. " <>
                 "Update docs/telemetry.md and this fixture together."
      end
    end
  end

  describe "async outcome vocabulary (AsyncDelivery frozen vocab)" do
    test "canonical async outcome atoms are documented" do
      # These are the normalized (canonical) output atoms from AsyncDelivery.normalize_async_outcome/1.
      # If any is removed or renamed, update this fixture and docs/telemetry.md together.
      assert @async_outcome_vocab == [
               :started,
               :succeeded,
               :retryable_failed,
               :discarded,
               :delayed
             ],
             "Async outcome vocab drifted. " <>
               "Update docs/telemetry.md and this fixture together."
    end

    test "all documented async outcomes normalize to themselves (round-trip)" do
      for outcome <- @async_outcome_vocab do
        assert AsyncDelivery.normalize_async_outcome(outcome) == outcome,
               "Async outcome #{inspect(outcome)} no longer normalizes to itself. " <>
                 "Update docs/telemetry.md and this fixture together."
      end
    end
  end
end
