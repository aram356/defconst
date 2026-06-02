defmodule Defconst.Enum.DefaultGenerator do
  @moduledoc """
  Default implementation of enum generator

  """

  @behaviour Defconst.Enum.Generator

  @doc """
  Returns the next enum value from the previous one.

  When the previous value is an integer, returns it incremented by one.
  When the previous value is a binary, returns it with `"1"` appended.

  ## Examples:
      iex> Defconst.Enum.DefaultGenerator.next_value(:three, 2)
      3

      iex> Defconst.Enum.DefaultGenerator.next_value(:bye, "hello")
      "hello1"

  """
  @spec next_value(atom(), integer()) :: integer()
  def next_value(_constant_name, previous_value) when is_integer(previous_value) do
    previous_value + 1
  end

  @spec next_value(atom(), String.t()) :: String.t()
  def next_value(_constant_name, previous_value) when is_binary(previous_value) do
    previous_value <> "1"
  end
end
