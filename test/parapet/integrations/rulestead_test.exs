defmodule Parapet.Integrations.RulesteadTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset) do
      send(self(), {:dummy_repo_insert, changeset})

      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      else
        {:error, changeset}
      end
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)

    # Detach to prevent duplicate handlers
    :telemetry.detach("parapet-rulestead-telemetry")
    Parapet.Integrations.Rulestead.attach()

    on_exit(fn ->
      :telemetry.detach("parapet-rulestead-telemetry")
      Application.delete_env(:parapet, :repo)
    end)

    :ok
  end

  test "attach/0 registers the telemetry handler" do
    handlers = :telemetry.list_handlers([:rulestead, :admin, :ruleset, :published])
    assert Enum.any?(handlers, fn h -> h.id == "parapet-rulestead-telemetry" end)
  end

  test "Parapet.attach(adapters: [:rulestead]) activates the handler via the uniform line" do
    # Detach first to start from a clean state
    :telemetry.detach("parapet-rulestead-telemetry")

    result = Parapet.attach(adapters: [:rulestead])
    assert result == {:ok, [:rulestead]}

    handlers = :telemetry.list_handlers([:rulestead, :admin, :ruleset, :published])
    assert Enum.any?(handlers, fn h -> h.id == "parapet-rulestead-telemetry" end)
  end

  test "firing telemetry inserts a SystemEvent with rulestead_flag_change type" do
    metadata = %{
      flag_name: "feature_x",
      ruleset_id: "rs_123",
      published_by: "user_456"
    }

    :telemetry.execute([:rulestead, :admin, :ruleset, :published], %{}, metadata)

    assert_receive {:dummy_repo_insert, changeset}
    assert changeset.data.__struct__ == Parapet.Spine.SystemEvent
    assert Ecto.Changeset.get_field(changeset, :type) == "rulestead_flag_change"

    payload = Ecto.Changeset.get_field(changeset, :payload)
    assert payload["flag_name"] == "feature_x"
    assert payload["ruleset_id"] == "rs_123"
  end

  test "exceptions in the handler are rescued and do not crash the caller" do
    # Pass bad metadata that would cause a crash if not rescued
    assert Parapet.Integrations.Rulestead.handle_event(
             [:rulestead, :admin, :ruleset, :published],
             %{},
             :not_a_map,
             nil
           ) == :ok
  end

  describe "metrics" do
    test "Parapet.Metrics.Rulestead.metrics/0 returns the flag change counter" do
      metrics = Parapet.Metrics.Rulestead.metrics()

      assert Enum.any?(metrics, fn metric ->
               match?(%Telemetry.Metrics.Counter{}, metric) and
                 metric.event_name == [:parapet, :rulestead, :flag_change] and
                 metric.name == [:parapet_rulestead_flag_change_total]
             end)
    end

    test "firing rulestead telemetry causes parapet telemetry to execute" do
      test_pid = self()

      handler_id = "test-parapet-rulestead-flag-change"

      :telemetry.attach(
        handler_id,
        [:parapet, :rulestead, :flag_change],
        fn _event, measurements, metadata, _config ->
          send(test_pid, {:telemetry_executed, measurements, metadata})
        end,
        nil
      )

      metadata = %{
        flag_name: "feature_y",
        ruleset_id: "rs_999"
      }

      :telemetry.execute([:rulestead, :admin, :ruleset, :published], %{}, metadata)

      assert_receive {:telemetry_executed, _measurements, received_metadata}
      assert received_metadata.flag_name == "feature_y"
      assert received_metadata.ruleset == "rs_999"

      :telemetry.detach(handler_id)
    end
  end
end
