defmodule Parapet.SLO.RindleAsyncTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO.RindleAsync

  test "exposes the locked rindle slice catalog with retry noise downgraded" do
    slices = RindleAsync.slos()

    assert Enum.map(slices, & &1.name) == [
             :rindle_terminal_success,
             :rindle_queue_freshness,
             :rindle_callback_freshness,
             :rindle_long_running_stage,
             :rindle_funnel_regression
           ]

    terminal = Enum.find(slices, &(&1.name == :rindle_terminal_success))
    queue = Enum.find(slices, &(&1.name == :rindle_queue_freshness))
    callback = Enum.find(slices, &(&1.name == :rindle_callback_freshness))
    long_running = Enum.find(slices, &(&1.name == :rindle_long_running_stage))
    funnel = Enum.find(slices, &(&1.name == :rindle_funnel_regression))

    assert terminal.good_matchers[:outcome] == :succeeded
    assert terminal.total_matchers[:outcome] == [:succeeded, :discarded]
    assert queue.labels[:fault_plane] == :backlog
    assert callback.labels[:fault_plane] == :webhook
    assert long_running.bad_matchers[:outcome] == :retryable_failed
    assert long_running.alert_class == :diagnostic
    assert funnel.bad_matchers[:outcome] == [:retryable_failed, :discarded]
    assert funnel.alert_class == :warning
  end
end
