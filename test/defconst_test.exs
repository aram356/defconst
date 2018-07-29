defmodule DefconstTest do
  use ExUnit.Case
  doctest Defconst

  test "defconst" do
    assert Defconst.hello() == :world
  end

  test "defenum" do
    assert Defconst.hello() == :world
  end
end
