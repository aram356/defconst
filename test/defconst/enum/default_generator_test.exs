defmodule Defconst.Enum.DefaultGeneratorTest do
  use ExUnit.Case
  alias Defconst.Enum.DefaultGenerator

  doctest DefaultGenerator

  describe "next_value" do
    test "integer" do
      assert DefaultGenerator.next_value(100) == 101
    end

    test "binary" do
      assert DefaultGenerator.next_value("hello") == "hello1"
    end
  end
end
