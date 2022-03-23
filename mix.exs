defmodule Peg.MixProject do
  use Mix.Project


  @version "0.1.0"

  @url "https://github.com/robertdober/peg_to_parse"

  @description """
  PegToParse is a simple Peg Parser (w/o Memoization so beware of Left Recursive Grammars)

  It is a Combinator and not a Generator like, e.g. nimble_parsec (which has a nice peg like interface though)
  and is a great library with great performance which we are not aiming to replace or compete with.

  This library is inspired by Saša Jurić's talk [Parsing from first principles](https://www.youtube.com/watch?v=xNzoerDljjo)
  """
  def project do
    [
      aliases: [docs: &build_docs/1],
      app: :peg_to_parse,
      deps: deps(),
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: "0.1.0"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.14.4", only: [:test]},
      {:extractly, "~> 0.5.3", only: [:dev]},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "dev"]
  defp elixirc_paths(:dev), do: ["lib", "bench", "dev"]
  defp elixirc_paths(_), do: ["lib"]

  @prerequisites """
  run `mix escript.install hex ex_doc` and adjust `PATH` accordingly
  """
  defp build_docs(_) do
    Mix.Task.run("compile")
    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")
    Mix.shell().info("Using escript: #{ex_doc} to build the docs")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed, make sure to \n#{@prerequisites}"
    end

    args = ["Peg", @version, Mix.Project.compile_path()]
    opts = ~w[--main Peg --source-ref v#{@version} --source-url #{@url}]

    Mix.shell().info("Running: #{ex_doc} #{inspect(args ++ opts)}")
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
# SPDX-License-Identifier: Apache-2.0
