defmodule SrpcWorld.Client do
  @moduledoc """
  Client for making calls to an `SrpcWorld.Server`
  """

  require Logger

  ## ===============================================================================================
  ##
  ##  SrpcWorld Client GenServer
  ##
  ##  Simple API for calls using an SrpcClient accessing the SrpcWorld Server. The SrpcClient
  ##  connection is maintained as the GenServer state.
  ##
  ## ===============================================================================================
  use GenServer

  ## ===============================================================================================
  ##
  ##  Client
  ##
  ## ===============================================================================================
  @doc """
  Supervisor child spec 
  """
  def child_spec(_), do: %{id: __MODULE__, start: {__MODULE__, :start_link, [[]]}}

  @doc """
  Start `SrpcWorld.Client` `GenServer`
  """
  def start_link([]), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  ## -----------------------------------------------------------------------------------------------
  ##  Init client
  ## -----------------------------------------------------------------------------------------------
  @doc """
  Initialize client with no connection.
  """
  def init([]) do
    {:ok, :no_conn}
  end

  ## ===============================================================================================
  ##
  ##  Public API
  ##
  ## ===============================================================================================
  @doc """
  Say hello to `name`
  """
  def say_hello(name), do: GenServer.call(__MODULE__, {:hello, name})

  @doc """
  Reverse a string
  """
  def reverse(string), do: GenServer.call(__MODULE__, {:reverse, string})

  @doc """
  Close the current `SrpcClient.Connection`
  """
  def good_bye, do: GenServer.call(__MODULE__, :good_bye)

  @doc """
  Register user credentials with `SrpcWorld.Server`
  """
  def register(user_id, password), do: GenServer.call(__MODULE__, {:register, user_id, password})

  ## ===============================================================================================
  ##
  ##  GenServer Calls
  ##
  ## ===============================================================================================
  @doc """
  `GenServer` callback to close connection
  """
  def handle_call(:good_bye, _from, :no_conn), do: {:reply, "Not connected", :no_conn}

  def handle_call(:good_bye, _from, conn) do
    SrpcClient.close(conn)
    {:reply, "Hasta luego", :no_conn}
  end

  @doc """
  `GenServer` callback to make a call using the current `SrpcClient.Connection`. If there is no
  current connection one is created first.
  """
  ## -----------------------------------------------------------------------------------------------
  ##  Make call using GenServer state connection, or create connection if necessary and then make
  ##  the call.
  ## -----------------------------------------------------------------------------------------------
  def handle_call(term, _from, :no_conn), do: conn_call(term, connect())
  def handle_call(term, _from, conn), do: conn_call(term, {:ok, conn})

  ## ===============================================================================================
  ##
  ##  Private
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  If a connection exists, make the call
  ## -----------------------------------------------------------------------------------------------
  defp conn_call(term, {:ok, conn}), do: conn |> call(term)
  defp conn_call(_term, error), do: {:reply, error, :no_conn}

  ## -----------------------------------------------------------------------------------------------
  ##  Hello name
  ## -----------------------------------------------------------------------------------------------
  defp call(conn, {:hello, name}) do
    conn
    |> SrpcClient.get("/hello?name=#{name}")
    |> resp_reply(conn)
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Reverse string (binary)
  ## -----------------------------------------------------------------------------------------------
  defp call(conn, {:reverse, string}) when is_binary(string) do
    conn
    |> SrpcClient.post("/reverse", string)
    |> resp_reply(conn)
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Reverse integer bytes. Note the SrpcWorld server reverses bytes, not bits.
  ## -----------------------------------------------------------------------------------------------
  defp call(conn, {:reverse, int}) when is_integer(int) do
    data = :srpc_util.int_to_bin(int)

    conn
    |> SrpcClient.post("/reverse", data)
    |> case do
      {:ok, resp} ->
        {:reply, Base.encode16(resp), conn}

      error ->
        {:reply, error, conn}
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Reject reverse attempt
  ## -----------------------------------------------------------------------------------------------
  defp call(conn, {:reverse, whatever}) do
    {:reply, "Don't know how to reverse #{inspect(whatever)}", conn}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Register user
  ## -----------------------------------------------------------------------------------------------
  defp call(conn, {:register, user_id, password}) do
    {:reply, SrpcClient.register(conn, user_id, password), conn}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  If the resp term is OK, just send the actual resp; otherwise send the error term
  ## -----------------------------------------------------------------------------------------------
  defp resp_reply({:ok, resp}, conn), do: {:reply, resp, conn}
  defp resp_reply(error, conn), do: {:reply, error, conn}

  ## -----------------------------------------------------------------------------------------------
  ##  Create a lib connection to the SrpcWorld server
  ## -----------------------------------------------------------------------------------------------
  defp connect do
    case SrpcClient.connect() do
      {:invalid, _} = invalid ->
        connection_fail()
        invalid

      {:error, _} = error ->
        connection_fail()
        error

      success ->
        connection_success()
        success
    end
  end

  defp connection_success, do: Logger.info("Connected to #{url_proxy_string()}")
  defp connection_fail, do: Logger.error("Failed connecting to SrcpWorld.Server")

  ## -----------------------------------------------------------------------------------------------
  ##  String representation of the url and optional proxy in use.
  ## -----------------------------------------------------------------------------------------------
  defp url_proxy_string do
    server = Application.get_env(:srpc_client, :server)

    proxy =
      if server[:proxy] do
        "via proxy #{server[:proxy]}"
      else
        ""
      end

    "http://#{server[:host]}:#{server[:port]} #{proxy}"
  end
end
