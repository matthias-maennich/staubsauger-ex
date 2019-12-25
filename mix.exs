defmodule Staubsauger.MixProject do
  use Mix.Project

  def project do
    [
      app: :staubsauger,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Staubsauger.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:circuits_uart, "~> 1.4"},
    ]
  end
end
