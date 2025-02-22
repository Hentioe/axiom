defmodule Axiom.MixProject do
  use Mix.Project

  @version "0.1.0-rc.6"
  @description "An AI chat adapter."

  def project do
    [
      app: :axiom,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Axiom",
      description: @description,
      package: package(),
      source_url: "https://github.com/Hentioe/axiom",
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Package metadata
  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Hentioe/axiom"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Axiom.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, "~> 0.37.2", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:finch, "~> 0.19.0"}
    ]
  end
end
