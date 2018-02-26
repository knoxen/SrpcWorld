use Mix.Config

config :srpc_client,
  srpc_file: "priv/client.srpc",
  srpc_transport: SrpcPoison

config :srpc_client, :server,
  host: "localhost",
  port: 8082

config :srpc_poison, proxy: "http://localhost.charlesproxy.com:8888"
