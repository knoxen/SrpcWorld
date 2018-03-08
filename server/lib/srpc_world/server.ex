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

    # kncache needs to be running before user srpc can be registered. Do the registration after
    # a delay. This is demo code and not a typical task.
    :timer.apply_after(100, __MODULE__, :register_user_srpc, [])

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

  def register_user_srpc do
    srpc_handler = required_opt(:srpc_plug, :srpc_handler)

    user_id = "srpc"
    kdf_salt = Base.decode16!("C91C52D5A7D5BC9DD5B71BFE")
    srp_salt = Base.decode16!("D7B2E576176A8CA1E9A4EF7D7CEE2739969A4E36")

    verifier =
      Base.decode16!(
        "7E848BF2CCCB76B90E9525C6BCFE13ECC32EA5A0942698555DE161CB1F2D5A319350DA0E1AEB62CCBCCD286357F1F830AAEC9CA29EA5F50A189F057B2900F61A8D05DCC3C017989812F18EFD34B378E3CEEE27FADCAF25B79BF083953021C3FBACB68C321B2F4F2350655D7E41038A92243758488599B9026D910310EB576224670504449478A086E5CC43C80894D55D48B6C77C9E6B74EE494F301A7BB2BFA7483A272212324C400E9B21F04D9249FBA18B5238D2E0F2A3F641C40A3B79F38FACAD476CF98F1E17F675A81AC78465C99AADCD157B0242EF6DC81F71D491923F428C29C23B32525CA9565AE6E9BA68570707DCA50DBA3C9F6ED3AF9522AE54EE"
      )

    registration = %{
      user_id: user_id,
      kdf_salt: kdf_salt,
      srp_salt: srp_salt,
      verifier: verifier
    }

    srpc_handler.put_registration(user_id, registration)
  end
end
