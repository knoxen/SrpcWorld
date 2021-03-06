use Mix.Config

config :srpc_plug,
  srpc_file: "priv/server.srpc",
  srpc_handler: SrpcWorld.Server.SrpcHandler

config :plug, :statuses, %{
  451 => "Srpc Demo Expired"
}

config :cowboy,
  cowboy_opts: [
    port: 8082,
    acceptors: 5
  ]

config :entropy_string,
  bits: :session,
  charset: :charset32

config :kncache,
  caches: [
    srpc_exch: 30,
    srpc_nonce: 35,
    srpc_conn: 3600,
    srpc_reg: 3600,
    user_data: 3600
  ]
