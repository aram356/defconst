# Defconst

This package provides `defconst` macro for defining a single constant and `defenum` macro for defining a list of enumerated cosntant values.  The defined contants and enumerated constants are referencable in any expression as well as in guards statements.

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

Define `ConstType` module with constants
```elixir
defmodule ConstType do
  use Defconst

  defconst :one, 1
  defconst :two, 2
end
```

Use `ConstType` module

```elixir
defmodule ConstUse do
  require ConstType

  def const_value(x) do
    case x do
      ConstType.one -> "one"
      ConstType.two -> "two"
    end
  end

  def const_guard(x) when x == ConstType.two do
    "two"
  end
end
```

### defenum

Define `EnumType` module with default initial value to be 0
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
Use `EnumType` module

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

