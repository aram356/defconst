# Defconst

This package provides `defconst` macro for defining a single constant and `defenum` macro for defining a list of enumerated constant values.  The defined constants and enumerated constants are referencable in any expression as well as in guards statements.

## Installation

Defconst can be installed by adding `defconst` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:defconst, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/defconst](https://hexdocs.pm/defconst).

## Usage

### defconst

Define `ConstType1` module with constants
```elixir
defmodule ConstType1 do
  use Defconst

  defconst :one, 1
  defconst :two, 2
end
```

Use `ConstType1` module

```elixir
defmodule ConstUse1 do
  require ConstType1

  def const_value(x) do
    case x do
      ConstType1.one -> "one"
      ConstType1.two -> "two"
    end
  end

  def const_guard(x) when x == ConstType1.two do
    "two"
  end
end
```

### defenum

Define `EnumType1` module with default values
```elixir
defmodule EnumType1 do
  use Defconst

  defenum [
    :zero,
    :one,
    :two
  ]
end
```

Use `EnumType1` module
```elixir
defmodule EnumUse1 do
  require EnumType1

  def enum_value(x) do
    case x do
      EnumType1.zero -> "zero"
      EnumType1.one -> "one"
      EnumType1.two -> "two"
      _ -> "unknown"
    end
  end

  def enum_guard(x) when x == EnumType1.two do
    "two"
  end
end
```
Define `EnumType2` with specific values
```elixir
defmodule EnumType2 do
  use Defconst

  defenum [
    {:one, 1},
    {:nine, 9},
    {:ten, "ten"}
  ]
end
```

Define `EnumType3` using `EnumGenerator3`
```elixir
defmodule EnumGenerator3 do
  @behaviour Defconst.Enum.Generator

  def next_value(previous_value) do
    previous_value <> previous_value
  end
end
```

```elixir
defmodule TestEnumType4 do
  use Defconst

  defenum [
            {:one, "one"},
            {:nine, "nine"},
            :ten
          ],
          EnumGenerator3
end
```