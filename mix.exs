defmodule Defconst.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :defconst,
      deps: deps(),
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      version: @version,

      # Hex
      description: description(),
      package: package(),

      # Docs
      docs: [
        extras: ["README.md", "CHANGELOG.md"],
        main: "Defconst"
      ],
      homepage_url: "https://github.com/aram356/defconst",
      name: "Defconst",
      source_url: "https://github.com/aram356/defconst",
      dialyzer: [
        plt_local_path: "_build/plts",
        plt_core_path: "_build/plts"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description do
    """
    This library implements macros to define contants and enums that can be used in guards
    """
  end

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      maintainers: ["Aram Grigoryan"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/aram356/defconst"}
    }
  end
end
