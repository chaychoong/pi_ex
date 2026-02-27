defmodule PiExTest do
  use ExUnit.Case

  doctest PiEx

  test "greets the world" do
    assert PiEx.hello() == :world
  end
end
