defmodule Parapet.TestSupport.TelemetryForwarder do
  @moduledoc false

  def forward_ref(event, measurements, metadata, %{pid: pid, ref: ref}) do
    send(pid, {ref, event, measurements, metadata})
  end

  def forward_event(event, measurements, metadata, %{pid: pid}) do
    send(pid, {:telemetry_event, event, measurements, metadata})
  end

  def forward_named(event, measurements, metadata, %{pid: pid, name: name}) do
    send(pid, {name, event, measurements, metadata})
  end

  def forward_named_payload(_event, measurements, metadata, %{pid: pid, name: name}) do
    send(pid, {name, measurements, metadata})
  end

  def forward_measurements(_event, measurements, _metadata, %{pid: pid, name: name}) do
    send(pid, {name, measurements})
  end

  def forward_metadata(_event, _measurements, metadata, %{pid: pid, name: name}) do
    send(pid, {name, metadata})
  end

  def forward_metadata_event(_event, _measurements, metadata, %{pid: pid}) do
    send(pid, {:telemetry_event, metadata})
  end

  def forward_executed(_event, measurements, metadata, %{pid: pid}) do
    send(pid, {:telemetry_executed, measurements, metadata})
  end
end
