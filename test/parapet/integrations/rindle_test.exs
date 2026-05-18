defmodule Parapet.Integrations.RindleTest do
  use ExUnit.Case, async: false

  setup do
    Parapet.Integrations.Rindle.setup()

    test_pid = self()

    handler_ids = [
      {"test-parapet-async-stage-#{System.unique_integer()}", [:parapet, :async, :stage]},
      {"test-parapet-async-backlog-#{System.unique_integer()}", [:parapet, :async, :backlog]},
      {"test-parapet-async-callback-#{System.unique_integer()}", [:parapet, :async, :callback]}
    ]

    Enum.each(handler_ids, fn {handler_id, event_name} ->
      :telemetry.attach(
        handler_id,
        event_name,
        fn name, measurements, metadata, _config ->
          send(test_pid, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )
    end)

    on_exit(fn ->
      Enum.each(handler_ids, fn {handler_id, _event_name} ->
        :telemetry.detach(handler_id)
      end)
    end)

    :ok
  end

  test "stage progress emits bounded async stage metadata" do
    :telemetry.execute(
      [:rindle, :media, :started],
      %{duration: 25},
      %{pipeline_stage: "thumbnail generation", queue: "media", job_id: 42, media_id: "asset-7"}
    )

    assert_receive {:telemetry_event, [:parapet, :async, :stage], %{count: 1, duration_ms: 25},
                    metadata}

    assert metadata.integration == :rindle
    assert metadata.pipeline_stage == :thumbnail_generation
    assert metadata.queue == "media"
    assert metadata.outcome == :started
    assert metadata.retry_state == :first_attempt
    assert metadata.fault_plane == :worker
    assert metadata.refs == %{job_ref: 42}
    refute Map.has_key?(metadata, :job_id)
    refute Map.has_key?(metadata, :media_id)
  end

  test "retryable async failure stays distinct from discard" do
    :telemetry.execute(
      [:rindle, :media, :failed],
      %{duration_ms: 80},
      %{pipeline_stage: :transcode, queue: "media", attempt: 3, job_id: 1001}
    )

    assert_receive {:telemetry_event, [:parapet, :async, :stage], %{count: 1, duration_ms: 80},
                    metadata}

    assert metadata.outcome == :retryable_failed
    assert metadata.retry_state == :retrying
    assert metadata.pipeline_stage == :transcode
    assert metadata.refs == %{job_ref: 1001}
  end

  test "discarded work emits a distinct terminal outcome" do
    :telemetry.execute(
      [:rindle, :media, :discarded],
      %{duration_ms: 95},
      %{pipeline_stage: :transcode, queue: "media", job_id: 1002}
    )

    assert_receive {:telemetry_event, [:parapet, :async, :stage], %{count: 1, duration_ms: 95},
                    metadata}

    assert metadata.outcome == :discarded
    assert metadata.retry_state == :exhausted
    assert metadata.fault_plane == :worker
    assert metadata.refs == %{job_ref: 1002}
  end

  test "queue backlog emits the async backlog family" do
    :telemetry.execute(
      [:rindle, :media, :backlog],
      %{delay_ms: 42_000},
      %{queue: "media", job_id: 1003}
    )

    assert_receive {:telemetry_event, [:parapet, :async, :backlog],
                    %{count: 1, delay_ms: 42_000}, metadata}

    assert metadata.integration == :rindle
    assert metadata.queue == "media"
    assert metadata.outcome == :delayed
    assert metadata.delay_bucket == :under_5m
    assert metadata.fault_plane == :backlog
    assert metadata.refs == %{job_ref: 1003}
  end

  test "callback delay emits the async callback family instead of backlog" do
    :telemetry.execute(
      [:rindle, :media, :callback_delayed],
      %{delay_ms: 350_000},
      %{pipeline_stage: :reconcile, queue: "callbacks", webhook_id: "wh_123"}
    )

    assert_receive {:telemetry_event, [:parapet, :async, :callback],
                    %{count: 1, delay_ms: 350_000}, metadata}

    assert metadata.pipeline_stage == :reconcile
    assert metadata.queue == "callbacks"
    assert metadata.outcome == :delayed
    assert metadata.delay_bucket == :under_1h
    assert metadata.fault_plane == :webhook
    assert metadata.refs == %{webhook_ref: "wh_123"}
  end

  test "processed work emits succeeded stage metadata" do
    :telemetry.execute(
      [:rindle, :media, :processed],
      %{duration: 100},
      %{pipeline_stage: :transcode, queue: "media", attempt_number: 2, job_id: 1004}
    )

    assert_receive {:telemetry_event, [:parapet, :async, :stage], %{count: 1, duration_ms: 100},
                    metadata}

    assert metadata.outcome == :succeeded
    assert metadata.retry_state == :retrying
    assert metadata.pipeline_stage == :transcode
    assert metadata.refs == %{job_ref: 1004}
  end
end
