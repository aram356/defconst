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
    caller_module = __CALLER__.module

    quote do
      import unquote(__MODULE__)

      Module.register_attribute(unquote(caller_module), :constants, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    constants =
      env.module
      |> Module.get_attribute(:constants)
      |> Enum.reverse()

    constant_map = Enum.into(constants, %{})

    value_map =
      Enum.reduce(constants, %{}, fn {constant, value}, map ->
        member = Map.get(map, value)

        new_member =
          case member do
            nil -> [constant]
            _ -> member ++ [constant]
          end

        Map.put(map, value, new_member)
      end)

    quote do
      def _constants(), do: unquote(constants)

      @doc """
      Returns all constants as list of tuples

      ## Examples:
          iex> #{__MODULE__}.constants
          #{unquote(constants) |> Kernel.inspect()}

      """
      def constants(), do: unquote(constants)

      @doc """
      Returns constant for specified value

      ## Parameters:
        * value: value of a constant

      ## Examples:
          iex> #{__MODULE__}.constant_of(#{
        unquote(constants)
        |> Keyword.values()
        |> List.first()
        |> Kernel.inspect()
      })
          #{unquote(constants) |> Keyword.keys() |> List.first() |> Kernel.inspect()}

      """
      def constant_of(value) do
        constants = unquote(Macro.escape(value_map))[value]

        case constants do
          [constant] -> constant
          _ -> constants
        end
      end

      @doc """
      Returns value for specified constant

      ## Parameters:
        * constant: defined constant

      ## Examples:
          iex> #{__MODULE__}.constant_of(#{
        unquote(constants)
        |> Keyword.keys()
        |> List.first()
        |> Kernel.inspect()
      })
          #{unquote(constants) |> Keyword.values() |> List.first() |> Kernel.inspect()}

      """
      def value_of(constant) do
        unquote(Macro.escape(constant_map))[constant]
      end
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
      iex> ConstType.constants
      [{:one, 1}, {:two, 2}]
      iex> ConstUse.const_value(1)
      "one"
      iex> ConstUse.const_guard(2)
      "two"

  """
  defmacro defconst(name, value) do
    caller_module = __CALLER__.module
    var = Macro.var(name, __MODULE__)

    quote do
      Module.put_attribute(unquote(caller_module), :constants, {unquote(name), unquote(value)})

      @doc """
      Returns #{unquote(value)}

      ## Examples:
          iex> #{__MODULE__}.#{unquote(name)}()
          #{unquote(value) |> Kernel.inspect()}
      """
      defmacro unquote(var), do: unquote(value)
    end
  end

  @doc """
  Defines an enum with specified constant names and optional values

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
      iex> EnumType1.constants
      [zero: 0, one: 1, two: 2]
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
      iex> EnumType2.constants
      [zero: "zero", one: 1, nine: 9, ten: 10]
      iex> EnumUse2.enum_value(1)
      "one"
      iex> EnumUse2.enum_guard(10)
      "ten"

  """
  defmacro defenum(constants, quoted_generator \\ quote(do: Defconst.Enum.DefaultGenerator))

  defmacro defenum(constants, quoted_generator) do
    # Expand quoted module
    generator = Macro.expand(quoted_generator, __CALLER__)

    constants
    |> normalize(generator)
    |> Enum.reverse()
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

  defp normalize_contant(generator, constant_name, {accumulator, index}) do
    {[{constant_name, index} | accumulator], generator.next_value(constant_name, index)}
  end
end
