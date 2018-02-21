defmodule SrpcWorld.Server.PlugStack do
  @moduledoc """
  Plug stack for `SrpcWorld`.

  The `SrpcPlug` at the top of the stack decrypts each request on the way in and encrypts each
  response on the way out. Any plug placed before the `SrpcPlug` on the stack should not alter the
  connection request or response. The bodies are SRPC formatted packets that carry data
  integrity message authentication codes and hence will fail SRPC processing if altered in any
  way.

  The connection request (as specified by the original client request) is available to plugs
  below `SrpcPlug` on the stack *after* SRPC request processing. The connection response (as
  determined by plug processing below the `SrpcPlug`) is contained in the encrypted SRPC response.

  The plugs below `SrpcPlug` on the stack operate on the request as sent from the client and on a
  response as will be seen on the client *after* SRPC processing occurs there.
  """

  use Plug.Builder

  plug(SrpcPlug)

  plug(SrpcWorld.Server.Plug)
end
