# Used by "mix format"
locals_without_parens = [
  defconst: 2,
  defenum: 1,
  defenum: 2
]

[
  inputs: [
    "mix.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
