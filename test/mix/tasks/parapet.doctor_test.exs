defmodule Mix.Tasks.Parapet.DoctorTest do
  use ExUnit.Case, async: false

  setup do
    Mix.shell(Mix.Shell.Process)
    Application.put_env(:parapet, :slos, [])
    on_exit(fn -> Application.put_env(:parapet, :slos, []) end)
    :ok
  end

  test "passes when no slos exist" do
    assert Mix.Tasks.Parapet.Doctor.run([]) == :ok
  end

  test "passes when slos have valid runbooks" do
    Parapet.SLO.define(:good_slo,
      objective: 99.9,
      good_events: "rate(good)",
      total_events: "rate(total)",
      runbook: "https://example.com/runbook"
    )

    assert Mix.Tasks.Parapet.Doctor.run([]) == :ok
  end

  test "fails and halts when slo has empty runbook" do
    Parapet.SLO.define(:bad_slo,
      objective: 99.9,
      good_events: "rate(good)",
      total_events: "rate(total)",
      runbook: ""
    )

    assert catch_exit(Mix.Tasks.Parapet.Doctor.run([])) == {:shutdown, 2}

    assert_receive {:mix_shell, :error, [msg]}
    assert msg =~ "SLO :bad_slo is missing a valid runbook"
  end
end
