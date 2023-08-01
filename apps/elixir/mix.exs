defmodule Moos2.MixProject do
  use Mix.Project

  def project do
    [
      app: :moos2,
      version: "0.1.0",
      elixir: "~> 1.14",
      escript: escript(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def escript do
    [main_module: Moos2.Main]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:plug_cowboy, :spotify_ex, :floki]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.34.0"},
      {:httpoison, "~> 1.0.0"},
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.6.1"},
      {:spotify_ex, "~> 2.2.1"}
    ]
  end
end
