defmodule Threadline do
  @moduledoc false
  def log_audit(attrs) do
    # If a process registered as :threadline_test_receiver exists, send it there, else self
    receiver = Process.whereis(:threadline_test_receiver) || self()
    send(receiver, {:threadline_log_audit, attrs})
  end
end
