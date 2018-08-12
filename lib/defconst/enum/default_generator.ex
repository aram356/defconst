defmodule Defconst.Enum.DefaultGenerator do
  @moduledoc """
  Default implementation of enum generator

  """

  @behaviour Defconst.Enum.Generator

  @doc """
  Next value when previous value is integer

    ## Examples:
    iex> Defconst.Enum.DefaultGenerator.next_value(2)
    3

  """
  @spec next_value(Integer.t()) :: Integer.t()
  def next_value(previous_value) when is_integer(previous_value) do
    previous_value + 1
  end

  @doc """
  Next value when  previous value is binary

    ## Examples:
    iex> Defconst.Enum.DefaultGenerator.next_value("hello")
    "hello1"

  """
  @spec next_value(String.t()) :: String.t()
  def next_value(previous_value) when is_binary(previous_value) do
    previous_value <> "1"
  end
end
