defmodule SrpcWorld.Application.Mixfile do
  use Mix.Project

  def project do
    [
      app: :srpc_world_application,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SrpcWorld.Application, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:srpc_poison, path: "local/srpc_poison", compile: false},
      {:srpc_client, path: "local/srpc_client", compile: false},
      {:srpc_lib, path: "local/srpc_lib", compile: false, override: true},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev}
    ]
  end
end
