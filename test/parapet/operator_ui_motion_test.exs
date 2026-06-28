defmodule Parapet.OperatorUIMotionTest do
  use ExUnit.Case, async: true

  alias Parapet.TestSupport.OperatorUIPaths

  test "GUARD-05: operator_components has brand easing curve (whitespace/leading-zero-tolerant)" do
    for path <- OperatorUIPaths.component_paths() do
      content = File.read!(path)

      # D-10: tolerant regex matches both cubic-bezier(.2, 0, 0, 1) and cubic-bezier(0.2, 0, 0, 1)
      assert content =~ ~r/cubic-bezier\(\s*0?\.2\s*,\s*0\s*,\s*0\s*,\s*1\s*\)/,
             "Brand easing curve (cubic-bezier(.2,0,0,1)) not found in #{path}"
    end
  end

  test "GUARD-05: --motion-fast: 0ms and --motion-base: 0ms both zeroed under prefers-reduced-motion" do
    for path <- OperatorUIPaths.component_paths() do
      content = File.read!(path)

      # D-11: BOTH tokens must be zeroed (not just --motion-fast as in earlier assertion)
      assert content =~ "--motion-fast: 0ms",
             "--motion-fast: 0ms not found in #{path} — reduced-motion block may be missing or incomplete"

      assert content =~ "--motion-base: 0ms",
             "--motion-base: 0ms not found in #{path} — reduced-motion block may be missing or incomplete"
    end
  end
end
