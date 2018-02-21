defmodule SrpcWorld.Application do
  @moduledoc """
  Provide an `Application` and a `Supervisor` for `SrpcWorld`
  """

  use Application

  @doc """
  Start the `SrpcWorld.Application`

  The `SrpcWorld.Application` supervises an `SrpcWorld.Client` and an `SrpcWorld.Lights` server.
  """
  def start(_type, []) do
    Process.register(self(), __MODULE__)

    children = [
      SrpcWorld.Client,
      SrpcWorld.Lights
    ]

    opts = [
      strategy: :one_for_one,
      name: SrpcWorld.Sup
    ]

    Supervisor.start_link(children, opts)
  end
end
