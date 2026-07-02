defmodule Parapet.Metrics.EctoTest do
  use ExUnit.Case, async: true

  alias Parapet.Metrics.Ecto

  setup do
    # Clear any previous telemetry handlers for clean slate
    :telemetry.detach("parapet-ecto-handler")
    :ok
  end

  # ---------------------------------------------------------------------------
  # Test 4: behavioral bare-name :source invariant (D-08/D-09 guard)
  #
  # WHY this holds: Ecto sets :source from schema.__schema__(:source), which is
  # the value passed to `schema "parapet_incidents"` — a bare, prefix-free table
  # name. @schema_prefix only qualifies the FROM/JOIN clause for the Postgres
  # schema; it is never propagated into the :source metadata key. A future
  # refactor that leaked "parapet.parapet_incidents" into :source would silently
  # double Prometheus series cardinality — this assertion guards that invariant.
  # ---------------------------------------------------------------------------

  test "Test 4: real spine query emits bare :source == parapet_incidents (no schema qualifier)" do
    handler_id = "test-ecto-source-bare-name-#{System.unique_integer([:positive])}"
    test_pid = self()

    # Check out the sandbox connection and reset tables FIRST, before attaching
    # the telemetry handler, so the TRUNCATE from reset!() does not deliver a
    # nil-source event to our mailbox before the real spine query fires.
    # Using the atom form to avoid shadowing by `alias Parapet.Metrics.Ecto`.
    sandbox_mod = :"Elixir.Ecto.Adapters.SQL.Sandbox"
    :ok = sandbox_mod.checkout(Parapet.TestSupport.ConcurrencyRepo)
    Parapet.TestSupport.ConcurrencyBootstrap.reset!()

    # Use the raw Ecto query event from ConcurrencyRepo — this is where :source
    # originates from __schema__(:source), before any re-emission or processing.
    raw_event = [:parapet, :test_support, :concurrency_repo, :query]

    # Attach AFTER reset!, so the first message received is from the spine query.
    :telemetry.attach(
      handler_id,
      raw_event,
      fn _event, _measurements, metadata, %{pid: pid} ->
        send(pid, {:raw_ecto_metadata, metadata})
      end,
      %{pid: test_pid}
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    # Drive a real spine query through ConcurrencyRepo — Ecto will emit the
    # raw_event above with :source derived from Incident.__schema__(:source).
    Parapet.TestSupport.ConcurrencyRepo.all(Parapet.Spine.Incident)

    assert_receive {:raw_ecto_metadata, metadata}, 2000

    # Positive: bare table name, exactly as declared in `schema "parapet_incidents"`.
    assert metadata.source == "parapet_incidents",
           "Expected bare :source == \"parapet_incidents\", got: #{inspect(metadata.source)}"

    # Negative: :source must carry no dotted schema-qualifier segment.
    # A schema-qualified form would indicate @schema_prefix leaked into telemetry.
    refute String.contains?(to_string(metadata.source), "."),
           "Expected no schema qualifier in :source, got: #{inspect(metadata.source)}"
  end

  test "Test 1: Handle event from [:my_app, :repo, :query] converting native to ms" do
    # Attach the handler
    Ecto.setup([:my_app, :repo])

    test_pid = self()

    # We will attach to the event Ecto handler emits
    :telemetry.attach(
      "test-ecto-emitted",
      [:parapet, :ecto, :query],
      &Parapet.TestSupport.TelemetryForwarder.forward_measurements/4,
      %{pid: test_pid, name: :telemetry_measurements}
    )

    query_time_native = System.convert_time_unit(10, :millisecond, :native)
    queue_time_native = System.convert_time_unit(5, :millisecond, :native)

    :telemetry.execute(
      [:my_app, :repo, :query],
      %{query_time: query_time_native, queue_time: queue_time_native},
      %{source: "users"}
    )

    assert_receive {:telemetry_measurements, measurements}, 1000
    assert measurements.query_time_ms == 10
    assert measurements.queue_time_ms == 5

    :telemetry.detach("test-ecto-emitted")
  end

  test "Test 2: Set source label to metadata.source or \"_raw\"" do
    Ecto.setup([:my_app, :repo])

    test_pid = self()

    :telemetry.attach(
      "test-ecto-emitted-source",
      [:parapet, :ecto, :query],
      &Parapet.TestSupport.TelemetryForwarder.forward_metadata/4,
      %{pid: test_pid, name: :telemetry_metadata}
    )

    :telemetry.execute(
      [:my_app, :repo, :query],
      %{query_time: 1000, queue_time: 500},
      %{}
    )

    assert_receive {:telemetry_metadata, metadata}, 1000
    assert metadata.source == "_raw"

    :telemetry.execute(
      [:my_app, :repo, :query],
      %{query_time: 1000, queue_time: 500},
      %{source: "accounts"}
    )

    assert_receive {:telemetry_metadata, metadata2}, 1000
    assert metadata2.source == "accounts"

    :telemetry.detach("test-ecto-emitted-source")
  end

  test "Test 3: Defines separate distributions for query_time_ms and queue_time_ms, wrapped in try/rescue ArgumentError" do
    metrics = Ecto.metrics()

    # Find the distributions
    query_metric =
      Enum.find(metrics, fn m -> m.name == [:parapet, :ecto, :query, :query_time_ms] end)

    queue_metric =
      Enum.find(metrics, fn m -> m.name == [:parapet, :ecto, :query, :queue_time_ms] end)

    assert query_metric.__struct__ == Telemetry.Metrics.Distribution
    assert queue_metric.__struct__ == Telemetry.Metrics.Distribution

    assert query_metric.measurement == :query_time_ms
    assert queue_metric.measurement == :queue_time_ms

    assert :source in query_metric.tags
    assert :source in queue_metric.tags

    assert Ecto.setup([:my_app, :repo]) == :ok
  end
end
