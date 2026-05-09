defmodule Mix.Tasks.Verify.PublicApiTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  test "run/1 prints manifest and succeeds if public API modules have docs" do
    # Assuming Parapet module has docs
    output = capture_io(fn ->
      Mix.Tasks.Verify.PublicApi.run([])
    end)

    assert output =~ "Parapet"
    assert output =~ "has_docs"
  end
end
