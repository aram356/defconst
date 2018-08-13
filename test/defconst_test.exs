defmodule DefconstTest do
  use ExUnit.Case
  doctest Defconst

  describe "defconst" do
    defmodule TestConstType do
      use Defconst

      defconst :one, 1
      defconst :two, 2
    end

    defmodule TestConstGuard do
      require TestConstType

      def guard_fun(x) when x == TestConstType.one(), do: x
    end

    test "value" do
      require TestConstType

      assert TestConstType.one() == 1
      assert TestConstType.two() == 2
    end

    test "guard" do
      require TestConstType

      assert TestConstGuard.guard_fun(TestConstType.one()) == TestConstType.one()

      assert_raise FunctionClauseError, fn ->
        TestConstGuard.guard_fun(TestConstType.two())
      end
    end
  end

  describe "enum with default integer values" do
    defmodule TestEnumType1 do
      use Defconst

      defenum [
        :zero,
        :one,
        :two
      ]
    end

    defmodule TestEnumType1Guard do
      require TestEnumType1

      def guard_fun(x) when x == TestEnumType1.one(), do: x
    end

    test "value" do
      require TestEnumType1

      assert TestEnumType1.zero() == 0
      assert TestEnumType1.one() == 1
      assert TestEnumType1.two() == 2
    end

    test "guard" do
      require TestEnumType1

      assert TestEnumType1Guard.guard_fun(TestEnumType1.one()) == TestEnumType1.one()

      assert_raise FunctionClauseError, fn ->
        TestEnumType1Guard.guard_fun(TestEnumType1.two())
      end
    end
  end

  describe "enum with explicit integer values" do
    defmodule TestEnumType2 do
      use Defconst

      defenum [
        {:one, 1},
        {:nine, 9},
        :ten
      ]
    end

    defmodule TestEnumType2Guard do
      require TestEnumType2

      def guard_fun(x) when x == TestEnumType2.one(), do: x
    end

    test "value" do
      require TestEnumType2

      assert TestEnumType2.one() == 1
      assert TestEnumType2.nine() == 9
      assert TestEnumType2.ten() == 10
    end

    test "guard" do
      require TestEnumType2

      assert TestEnumType2Guard.guard_fun(TestEnumType2.one()) == TestEnumType2.one()

      assert_raise FunctionClauseError, fn ->
        TestEnumType2Guard.guard_fun(TestEnumType2.nine())
      end
    end
  end

  describe "enum with explicit string values" do
    defmodule TestEnumType3 do
      use Defconst

      defenum [
        {:one, "one"},
        {:nine, "nine"},
        :ten
      ]
    end

    defmodule TestEnumType3Guard do
      require TestEnumType3

      def guard_fun(x) when x == TestEnumType3.one(), do: x
    end

    test "value" do
      require TestEnumType3

      assert TestEnumType3.one() == "one"
      assert TestEnumType3.nine() == "nine"
      assert TestEnumType3.ten() == "nine1"
    end

    test "guard" do
      require TestEnumType3

      assert TestEnumType3Guard.guard_fun(TestEnumType3.one()) == TestEnumType3.one()

      assert_raise FunctionClauseError, fn ->
        TestEnumType3Guard.guard_fun(TestEnumType3.nine())
      end
    end
  end

  describe "enum with explicit generator" do
    defmodule TestGenerator1 do
      @behaviour Defconst.Enum.Generator

      def next_value(_constant_name, previous_value) do
        previous_value <> previous_value
      end
    end

    defmodule TestEnumType4 do
      use Defconst

      defenum [
                {:one, "one"},
                {:nine, "nine"},
                :ten
              ],
              TestGenerator1
    end

    test "value" do
      require TestEnumType4

      assert TestEnumType4.one() == "one"
      assert TestEnumType4.nine() == "nine"
      assert TestEnumType4.ten() == "ninenine"
    end
  end
end
