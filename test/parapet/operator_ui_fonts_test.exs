defmodule Parapet.OperatorUIFontsTest do
  use ExUnit.Case, async: true

  @font_dir "priv/static/parapet/fonts"
  @font_budget_bytes 153_600  # 150 KB ceiling per D-09

  @font_files ~w(
    IBMPlexSans-Regular-latin.woff2
    IBMPlexSans-Medium-latin.woff2
    IBMPlexSans-SemiBold-latin.woff2
    IBMPlexMono-Regular-latin.woff2
    IBMPlexMono-Medium-latin.woff2
  )

  test "all IBM Plex woff2 files are vendored" do
    for filename <- @font_files do
      path = Path.join(@font_dir, filename)
      assert File.exists?(path), "Missing font file: #{path}"
    end
  end

  test "IBM Plex OFL license is vendored" do
    assert File.exists?(Path.join(@font_dir, "LICENSE.txt"))
  end

  test "total font budget is within 150 KB ceiling" do
    total =
      @font_files
      |> Enum.map(&Path.join(@font_dir, &1))
      |> Enum.map(&File.stat!(&1).size)
      |> Enum.sum()

    assert total <= @font_budget_bytes,
           "Font budget #{total} bytes exceeds #{@font_budget_bytes} byte ceiling"
  end

  test "each font file is a valid woff2 binary (non-zero, non-empty)" do
    for filename <- @font_files do
      path = Path.join(@font_dir, filename)
      stat = File.stat!(path)
      assert stat.size > 0, "Font file #{filename} is empty"
    end
  end
end
