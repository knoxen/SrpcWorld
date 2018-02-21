defmodule SrpcWorld.Server.SrpcHandler do
  @moduledoc """
  Provide required and optional functions needed by SRPC processing module `srpc_srv`.
  """

  @behaviour :srpc_handler

  defmodule ConnId do
    @moduledoc """
    Provide random strings from the `EntropyString.CharSet.charset32/0` character set.
    See [EntropyString](https://hexdocs.pm/entropy_string/EntropyString.html)
    """
    use(EntropyString, charset: EntropyString.CharSet.charset32())
  end

  @doc """
  Provide 126-bit entropy random string for connection ID.
  """
  def conn_id, do: ConnId.session_id()

  @doc """
  Store SRPC exchange info. Exchange info is ephemeral data related to a connection that has yet
  to be SRPC confirmed.
  """
  def put_exchange(conn_id, value) do
    :kncache.put(conn_id, value, :srpc_exch)
  end

  @doc """
  Retrieve SRPC exchange info.
  """
  def get_exchange(conn_id) do
    :kncache.get(conn_id, :srpc_exch)
  end

  @doc """
  Delete SRPC exchange info.
  """
  def delete_exchange(conn_id) do
    :kncache.delete(conn_id, :srpc_exch)
  end

  @doc """
  Store SRPC connection info. This relates to data for an SRPC confirmed connection.
  """
  def put_conn(conn_id, value) do
    :kncache.put(conn_id, value, :srpc_conn)
  end

  @doc """
  Retrieve SRPC connection info.
  """
  def get_conn(conn_id) do
    :kncache.get(conn_id, :srpc_conn)
  end

  @doc """
  Delete SRPC connection info.
  """
  def delete_conn(conn_id) do
    :kncache.delete(conn_id, :srpc_conn)
  end

  @doc """
  Store SRPC registration info.
  """
  def put_registration(user_id, value) do
    :kncache.put(user_id, value, :srpc_reg)
  end

  @doc """
  Retrieve SRPC registration info.
  """
  def get_registration(user_id) do
    :kncache.get(user_id, :srpc_reg)
  end

  @doc """
  A value in seconds representing the maximum age for a request. A value of 0 negates the age check.
  __*Optional*__
  """
  def req_age_tolerance, do: 30

  @doc """
  Determine whether a request nonce is valid. Nonces are only checked if the request age is being
  validated, in which case the nonces only need to be retained for a period slightly longer than 
  the request age tolerance itself.
  __*Optional*__
  """
  def nonce(nonce) do
    case :kncache.get(nonce, :srpc_nonce) do
      :undefined ->
        :kncache.put(nonce, :erlang.system_time(:seconds), :srpc_nonce)
        true

      _ ->
        false
    end
  end

  @doc """
  Store application data passed in an SRPC registration request and return any application data to
  pass back in the SRPC registration response.
  __*Optional*__
  """
  def registration_data(user_id, reg_data) do
    :kncache.put(user_id, reg_data, :user_data)
    ""
  end
end
