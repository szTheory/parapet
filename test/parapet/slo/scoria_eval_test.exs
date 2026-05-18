defmodule Parapet.SLO.ScoriaEvalTest do
  use ExUnit.Case

  alias Parapet.SLO.ScoriaEval

  describe "new/1" do
    test "raises ArgumentError when missing required properties" do
      assert_raise ArgumentError,
                   ~r/missing required fields for ScoriaEval my_eval: \[:objective, :guardrail, :runbook\]/,
                   fn ->
                     ScoriaEval.new(name: :my_eval)
                   end
    end

    test "creates struct with valid properties" do
      eval =
        ScoriaEval.new(
          name: :my_eval,
          objective: 99.9,
          guardrail: "toxicity",
          runbook: "http://runbook.com"
        )

      assert eval.name == :my_eval
      assert eval.objective == 99.9
      assert eval.guardrail == "toxicity"
      assert eval.runbook == "http://runbook.com"
      assert eval.labels == %{}
    end
  end

  describe "Parapet.SLO.Resolvable" do
    test "to_slo/1 converts ScoriaEval to a standard Parapet.SLO" do
      eval =
        ScoriaEval.new(
          name: :my_eval,
          objective: 99.9,
          guardrail: "toxicity",
          runbook: "http://runbook.com",
          labels: %{model_name: "gpt-4"}
        )

      slo = Parapet.SLO.Resolvable.to_slo(eval)

      assert slo.name == :my_eval
      assert slo.objective == 99.9
      assert slo.runbook == "http://runbook.com"

      assert slo.good_events ==
               "sum(rate(scoria_evaluation_total{guardrail=\"toxicity\", passed=\"true\", model_name=\"gpt-4\"}[window]))"

      assert slo.total_events ==
               "sum(rate(scoria_evaluation_total{guardrail=\"toxicity\", model_name=\"gpt-4\"}[window]))"
    end
  end
end
