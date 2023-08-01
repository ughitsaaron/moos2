defmodule Moos2Test do
  use ExUnit.Case
  doctest Moos2

  test "greets the world" do
    assert Moos2.hello() == :world
  end
end
