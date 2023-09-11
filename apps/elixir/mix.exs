defmodule Moos2.MixProject do
  use Mix.Project

  def project do
    [
      app: :moos2,
      version: "0.0.1",
      elixir: "~> 1.14",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:poison, "~> 5.0"},
      {:floki, "~> 0.34.0"},
      {:httpoison, "~> 2.0"}
    ]
  end
end
