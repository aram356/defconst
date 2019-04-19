defmodule Defconst.MixProject do
  use Mix.Project

  @version "0.2.3"

  def project do
    [
      app: :defconst,
      deps: deps(),
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      version: @version,

      # Hex
      description: description(),
      package: package(),
      # Docs
      docs: [
        extras: ["README.md"],
        main: "Defconst"
      ],
      homepage_url: "https://github.com/aram356/defconst",
      name: "Defconst",
      source_url: "https://github.com/aram356/defconst"
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
    [{:ex_doc, "~> 0.20", only: :dev, runtime: false}]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Aram Grigoryan"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/aram356/defconst"}
    }
  end
end
