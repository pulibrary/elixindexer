defmodule Elixindexer.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixindexer,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Elixindexer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchfella, "~> 0.3.0", only: [:dev, :test]},
      {:flow, "~> 0.13"},
      {:exprof, "~> 0.2.0", only: [:dev, :test]},
      {:jiffy, "~> 0.15.1"},
      {:elsol, github: "findmypast/elsol"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
