# Defconst

[![CI](https://github.com/aram356/defconst/actions/workflows/ci.yml/badge.svg)](https://github.com/aram356/defconst/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/defconst.svg)](https://hex.pm/packages/defconst)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/defconst)
[![License](https://img.shields.io/hexpm/l/defconst.svg)](LICENSE)

This package provides `defconst` macro for defining a single constant and `defenum` macro for defining a list of enumerated constant values. The defined constants and enumerated constants are referencable in any expression as well as in guards statements.

Documentation is published at [hexdocs.pm/defconst](https://hexdocs.pm/defconst).

## Requirements

Elixir `~> 1.15` (tested on 1.15–1.19 / OTP 26–28). The library has no runtime dependencies.

## Installation

Defconst can be installed by adding `defconst` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:defconst, "~> 0.4.0"}
  ]
end
```

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

### Introspection

Modules that `use Defconst` also expose:

- `constants/0` — all constants as `[{name, value}, ...]`
- `value_of/1` — the value for a constant name
- `constant_of/1` — the constant name for a value (a list if several share the value, `nil` if none)

```elixir
ConstType1.constants()        #=> [{:one, 1}, {:two, 2}]
ConstType1.value_of(:one)     #=> 1
ConstType1.constant_of(2)     #=> :two
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

  def next_value(_constant_name, previous_value) do
    previous_value <> previous_value
  end
end
```

```elixir
defmodule TestEnumType3 do
  use Defconst

  defenum [
            {:one, "one"},
            {:nine, "nine"},
            :ten
          ],
          EnumGenerator3
end
```

## Development

```sh
mix deps.get
mix test
mix format --check-formatted
mix credo --strict
mix dialyzer
mix docs
```

The toolchain is pinned in `.tool-versions` (Elixir 1.19.5 / OTP 28). CI runs the test suite
across Elixir 1.15–1.19 / OTP 26–28 plus a formatting check.

## Releasing

Releases are published to Hex automatically by CI
([`.github/workflows/release.yml`](.github/workflows/release.yml)):

1. Bump `@version` in `mix.exs` and update [`CHANGELOG.md`](CHANGELOG.md).
2. Publish a GitHub Release whose tag matches the version (e.g. `v0.3.0`).
3. CI verifies the tag matches `mix.exs` and runs `mix hex.publish` (package + docs).

This requires a `HEX_API_KEY` secret (a write-scoped Hex key) configured in the repository's
Actions secrets.

## License

Apache-2.0 — see [LICENSE](LICENSE).
