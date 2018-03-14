defmodule SrpcWorld.Server.Mixfile do
  use Mix.Project

  def project do
    [
      app: :srpc_world_server,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SrpcWorld.Server, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.4"},
      {:cowboy, "~> 1.1"},
      {:entropy_string, "~> 1.2"},
      {:poison, "~> 3.1"},
      {:srpc_plug, path: "local/srpc_plug", compile: false},
      {:srpc_srv, path: "local/srpc_srv", compile: false, override: true},
      {:srpc_lib, path: "local/srpc_lib", compile: false, override: true},
      {:kncache, git: "https://github.com/knoxen/kncache.git", tag: "0.12.0"},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev}
    ]
  end
end
