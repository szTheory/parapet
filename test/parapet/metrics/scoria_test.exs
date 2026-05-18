defmodule Parapet.Metrics.ScoriaTest do
  use ExUnit.Case

  alias Parapet.Metrics.Scoria

  setup do
    Scoria.setup()

    on_exit(fn ->
      :telemetry.detach("parapet-scoria-eval-handler")
    end)

    :ok
  end

  test "handler sanitizes metadata and emits downstream event" do
    parent = self()

    :telemetry.attach(
      "test-scoria-downstream",
      [:parapet, :scoria, :eval, :completed],
      fn _name, measurements, metadata, _config ->
        send(parent, {:downstream_event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("test-scoria-downstream")
    end)

    # Emit the upstream event with extra high-cardinality metadata
    :telemetry.execute(
      [:scoria, :eval, :completed],
      %{duration: 120},
      %{
        guardrail: "toxicity",
        passed: true,
        model_name: "gpt-4",
        trace_id: "abc-123-trace",
        prompt_hash: "xyz789",
        other_stuff: "secret"
      }
    )

    assert_receive {:downstream_event, measurements, metadata}

    # Assert measurements are passed through
    assert measurements == %{duration: 120}

    # Assert only safe keys are present in metadata
    assert metadata == %{
             guardrail: "toxicity",
             passed: true,
             model_name: "gpt-4"
           }
  end

  test "metrics definition matches downstream event" do
    metrics = Scoria.metrics()

    assert [eval_counter, mcp_counter] = metrics

    # Telemetry.Metrics representation of "scoria_evaluation_total"
    assert eval_counter.name == [:scoria_evaluation_total]
    assert eval_counter.event_name == [:parapet, :scoria, :eval, :completed]
    assert eval_counter.tags == [:guardrail, :passed, :model_name]

    assert mcp_counter.name == [:scoria_mcp_errors_total]
    assert mcp_counter.event_name == [:parapet, :scoria, :mcp, :error]
    assert mcp_counter.tags == [:reason, :tool_name]
  end
end
