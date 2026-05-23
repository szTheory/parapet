defmodule Parapet.Metrics.ValidatorTest do
  use ExUnit.Case, async: true

  # We test the compilation failures by defining modules dynamically
  # within tests or asserting on `Code.compile_string/1` exceptions.

  test "compiles successfully with safe metrics" do
    assert [{module, _}] = Code.compile_string("""
      defmodule Parapet.Metrics.ValidatorTest.SafeMetrics do
        use Parapet.Metrics.Validator

        def metrics do
          [
            Telemetry.Metrics.counter("parapet.safe.count", tags: [:status, :route])
          ]
        end
      end
    """)
    assert module == Parapet.Metrics.ValidatorTest.SafeMetrics
  end

  test "raises CompileError if exceeding max labels" do
    assert_raise CompileError, ~r/exceeds max cardinality limit/, fn ->
      Code.compile_string("""
        defmodule Parapet.Metrics.ValidatorTest.TooManyLabels do
          use Parapet.Metrics.Validator, max_labels: 2

          def metrics do
            [
              Telemetry.Metrics.counter("parapet.safe.count", tags: [:one, :two, :three])
            ]
          end
        end
      """)
    end
  end

  test "raises ArgumentError if using unsafe labels" do
    assert_raise ArgumentError, ~r/High cardinality label rejected by Parapet safety policy/, fn ->
      Code.compile_string("""
        defmodule Parapet.Metrics.ValidatorTest.UnsafeLabels do
          use Parapet.Metrics.Validator

          def metrics do
            [
              Telemetry.Metrics.counter("parapet.unsafe.count", tags: [:user_id])
            ]
          end
        end
      """)
    end
  end
end
