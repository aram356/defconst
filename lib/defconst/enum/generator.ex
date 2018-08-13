defmodule Defconst.Enum.Generator do
  @moduledoc """
  Callbacks definition for generating enum values
  """

  @callback next_value(atom(), any()) :: any()
end
