defmodule SrpcWorld.Server do
  @moduledoc """
  Provide an `Application` and a `Supervisor` for `SrpcWorld.Server`
  """

  use Application

  @doc """
  Start the `SrpcWorld.Server` application

  The `SrpcWorld.Server` application supervises a `Plug.Adapters.Cowboy` HTTP server, a set of
  lights in `SrpcWorld.Lights`, and a simple cache which maintains data required by SRPC.
  """
  def start(_type, []) do
    Process.register(self(), __MODULE__)

    cowboy_opts = required_opt(:cowboy, :cowboy_opts)
    port = cowboy_opts |> Keyword.get(:port)
    require Logger
    Logger.info("Listening on port #{port}")

    kncache_opts = required_opt(:kncache, :caches)

    children = [
      Plug.Adapters.Cowboy.child_spec(
        :http,
        SrpcWorld.Server.PlugStack,
        [],
        cowboy_opts
      ),
      SrpcWorld.Lights,
      {:kncache, [kncache_opts]}
    ]

    opts = [
      strategy: :one_for_one,
      name: SrpcWorld.Server.Sup
    ]

    Supervisor.start_link(children, opts)
  end

  def start(_type, args), do: throw("Not expecting any args: #{inspect(args)}")

  ## ===============================================================================================
  ##
  ##  Private
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Retrieve option from env and raise an error if missing
  ## -----------------------------------------------------------------------------------------------
  defp required_opt(mod, name) do
    unless option = Application.get_env(mod, name) do
      raise("Missing option: #{name}")
    end

    option
  end
end
