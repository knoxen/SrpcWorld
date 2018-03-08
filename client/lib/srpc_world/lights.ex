defmodule SrpcWorld.Lights do
  @moduledoc """
  Control a set of lights on an `SrpcWorld.Server`
  """

  require Logger

  ## ===============================================================================================
  ##
  ##  GenServer
  ##
  ##  Simple API for a SrcpWorld client
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
  Start `SrpcWorld.Lights` `GenServer`
  """
  def start_link([]), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  ## -----------------------------------------------------------------------------------------------
  ##  Init with no connection
  ## -----------------------------------------------------------------------------------------------
  @doc """
  Initialize `GenServer` with no `SrpcClient.Connection`
  """
  def init([]) do
    {:ok, :no_conn}
  end

  ## ===============================================================================================
  ##
  ##  Public API
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Login
  ## -----------------------------------------------------------------------------------------------
  @doc """
  Login to `SrpcWorld.Server` to control lights
  """
  def login(user_id, password), do: GenServer.call(__MODULE__, {:login, user_id, password})

  @doc """
  Logout from `SrpcWorld.Server`
  """
  def logout, do: GenServer.call(__MODULE__, :logout)

  @doc """
  Status of lights as a map of `light` associated to either `on` or `off`
  """
  def status, do: GenServer.call(__MODULE__, :status)

  @doc """
  Switch lights so that only `light` is `on`
  """
  def switch(light), do: GenServer.call(__MODULE__, {:action, :switch, light})

  @doc """
  Turn `light` `on`
  """
  def on(light), do: GenServer.call(__MODULE__, {:action, :on, light})

  @doc """
  Turn `light` `off`
  """
  def off(light), do: GenServer.call(__MODULE__, {:action, :off, light})

  ## ===============================================================================================
  ##
  ##  GenServer Calls
  ##
  ## ===============================================================================================
  @doc """
  Handle `GenServer` callbacks
  """
  def handle_call({:login, id, pw}, _from, conn), do: login(conn, id, pw)
  def handle_call(:logout, _from, conn), do: logout(conn)
  def handle_call(:status, _from, conn), do: status(conn)
  def handle_call({:action, action, light}, _from, conn), do: action(conn, action, light)

  ## -----------------------------------------------------------------------------------------------
  ##  Login (establish connection)
  ## -----------------------------------------------------------------------------------------------
  defp login(:no_conn, user_id, password) do
    case SrpcClient.connect(user_id, password) do
      {:ok, conn} ->
        {:reply, :ok, conn}

      error ->
        {:reply, error, :no_conn}
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Logout existing connection and login
  ## -----------------------------------------------------------------------------------------------
  defp login(conn, user_id, password) do
    SrpcClient.close(conn)
    login(:no_conn, user_id, password)
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Logout 
  ## -----------------------------------------------------------------------------------------------
  defp logout(:no_conn), do: {:reply, "Not logged in", :no_conn}

  defp logout(conn) do
    SrpcClient.close(conn)
    {:reply, :ok, :no_conn}
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Status of lights
  ## -----------------------------------------------------------------------------------------------
  defp status(:no_conn), do: {:reply, "Login to get status", :no_conn}

  defp status(conn) do
    conn
    |> SrpcClient.get("/status")
    |> status_reply
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Perform action on lights
  ## -----------------------------------------------------------------------------------------------
  defp action(:no_conn, _, _), do: {:reply, "Login to access lights", :no_conn}

  defp action(conn, action, light) do
    action = Poison.encode!(%{action: action, light: light})

    conn
    |> SrpcClient.post("/action", action)
    |> status_reply
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Reply with the status as a map, or as an error term
  ## -----------------------------------------------------------------------------------------------
  defp status_reply({{:ok, status}, conn}), do: {:reply, Poison.decode!(status), conn}
  defp status_reply({error, conn}), do: {:reply, error, conn}
end
