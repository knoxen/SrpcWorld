use Mix.Config

config :srpc_client, srpc_file: "priv/client.srpc"

config :srpc_client, :server,
  host: "localhost",
  port: 8082
