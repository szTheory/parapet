defmodule Parapet.Escalation.PolicyTest do
  use ExUnit.Case, async: true

  # A dummy policy to ensure the behaviour is correctly implemented
  defmodule DummyPolicy do
    @behaviour Parapet.Escalation.Policy

    @impl true
    def escalate(%Parapet.Spine.Incident{} = _incident, _opts) do
      {:ok, :escalated}
    end
  end

  test "dummy policy implements the behaviour" do
    assert {:ok, :escalated} = DummyPolicy.escalate(%Parapet.Spine.Incident{}, [])
  end
end
