defmodule BrickPi3.Constant do
  @moduledoc """
  """

  defmacro __using__(_opts) do
    quote do
      import BrickPi3.Constant
    end
  end

  @doc """
  """
  defmacro defconst(name, value) do
    quote do
      defmacro unquote(name)(), do: unquote(value)
    end
  end

  defmacro defenum(constants) do
    constants
    |> normalize
    |> Enum.map(fn {name, value} ->
      quote do
        defconsdefconsttant(unquote(name), unquote(value))
      end
    end)
  end

  @doc """
  """
  defp normalize(constants) do
    {result, _} =
      Enum.reduce(constants, {[], 0}, fn
        {_name, value} = constant, {accumulator, _index} -> {[constant | accumulator], value + 1}
        name, {accumulator, index} -> {[{name, index} | accumulator], index + 1}
      end)

    result
  end
end
