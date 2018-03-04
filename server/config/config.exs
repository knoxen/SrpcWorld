use Mix.Config

config :srpc_plug,
  srpc_file: "priv/server.srpc",
  srpc_handler: SrpcWorld.Server.SrpcHandler

config :cowboy,
  cowboy_opts: [
    port: 8082,
    acceptors: 5
  ]

config :kncache,
  caches: [
    srpc_exch: 30,
    srpc_nonce: 35,
    srpc_conn: 3600,
    srpc_reg: 3600,
    user_data: 3600
  ]
