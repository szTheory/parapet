defmodule ParapetTest do
  use ExUnit.Case
  doctest Parapet

  test "greets the world" do
    assert Parapet.hello() == :world
  end
end
