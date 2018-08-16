defmodule Defconst do
  @moduledoc """
  Define constants and enum with use in guards

  ## Define a contant
      defmodule ConstType do
        use Defconst

        defconst :one, 1
        defconst :two, 2
      end

  ## Define an enum with default values
      defmodule EnumType1 do
        use Defconst

        defenum [
          :zero,
          :one,
          :two
        ]
      end

  ## Define an enum with explicit values
      defmodule EnumType2 do
        use Defconst

        defenum [
          {:one, 1},
          {:nine, 9},
          :ten
        ]
      end

  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Defconst
    end
  end

  @doc """
  Define constant

  ## Examples:
      iex> defmodule ConstType do
      ...>   use Defconst
      ...>
      ...>   defconst :one, 1
      ...>   defconst :two, 2
      ...> end
      iex> defmodule ConstUse do
      ...>   require ConstType
      ...>
      ...>   def const_value(x) do
      ...>     case x do
      ...>       ConstType.one -> "one"
      ...>       ConstType.two -> "two"
      ...>       _ -> "unknown"
      ...>     end
      ...>   end
      ...>
      ...>   def const_guard(x) when x == ConstType.two do
      ...>     "two"
      ...>   end
      ...> end
      iex> ConstUse.const_value(1)
      "one"
      iex> ConstUse.const_guard(2)
      "two"

  """
  defmacro defconst(name, value) do
    var = Macro.var(name, __MODULE__)

    quote do
      defmacro unquote(var), do: unquote(value)
    end
  end

  @doc """
  Define enum

  ## Examples:
      iex> defmodule EnumType1 do
      ...>   use Defconst
      ...>
      ...>   defenum [
      ...>     :zero,
      ...>     :one,
      ...>     :two
      ...>   ]
      ...> end
      iex> defmodule EnumUse1 do
      ...>   require EnumType1
      ...>
      ...>   def enum_value(x) do
      ...>     case x do
      ...>       EnumType1.zero -> "zero"
      ...>       EnumType1.one -> "one"
      ...>       EnumType1.two -> "two"
      ...>       _ -> "unknown"
      ...>     end
      ...>   end
      ...>
      ...>   def enum_guard(x) when x == EnumType1.two do
      ...>     "two"
      ...>   end
      ...> end
      iex> EnumUse1.enum_value(1)
      "one"
      iex> EnumUse1.enum_guard(2)
      "two"

      iex> defmodule EnumType2 do
      ...>   use Defconst
      ...>
      ...>   defenum [
      ...>     {:zero, "zero"},
      ...>     {:one, 1},
      ...>     {:nine, 9},
      ...>     :ten
      ...>   ]
      ...> end
      iex> defmodule EnumUse2 do
      ...>   require EnumType2
      ...>
      ...>   def enum_value(x) do
      ...>     case x do
      ...>       EnumType2.zero -> "zero"
      ...>       EnumType2.one -> "one"
      ...>       EnumType2.nine -> "nine"
      ...>       EnumType2.ten -> "ten"
      ...>       _ -> "unknown"
      ...>     end
      ...>   end
      ...>
      ...>   def enum_guard(x) when x == EnumType2.ten do
      ...>     "ten"
      ...>   end
      ...> end
      iex> EnumUse2.enum_value(1)
      "one"
      iex> EnumUse2.enum_guard(10)
      "ten"

  """

  defmacro defenum(constant, quoted_generator \\ quote(do: Defconst.Enum.DefaultGenerator))

  defmacro defenum(constants, quoted_generator) do
    # Expand quoted module
    generator = Macro.expand(quoted_generator, __CALLER__)

    constants
    |> normalize(generator)
    |> Enum.map(fn {name, value} ->
      quote do
        defconst(unquote(name), unquote(value))
      end
    end)
  end

  defp normalize(constants, generator) do
    {result, _} = Enum.reduce(constants, {[], 0}, &normalize_contant(generator, &1, &2))

    result
  end

  defp normalize_contant(generator, {constant_name, value} = constant, {accumulator, _index}) do
    {[constant | accumulator], generator.next_value(constant_name, value)}
  end

  defp normalize_contant(generator, constant_name, {accumulator, value}) do
    {[{constant_name, value} | accumulator], generator.next_value(constant_name, value)}
  end
end
