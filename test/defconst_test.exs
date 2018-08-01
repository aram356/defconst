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

  describe "enum with default values" do      
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

  describe "enum with explicit values" do
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
end
