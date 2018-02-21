defmodule SrpcWorld.Server.Plug do
  @moduledoc """
  Provide HTTP processing for `SrpcWorld`.
  """

  ## ===============================================================================================
  ##
  ##  SrpcWorld Plug 
  ##
  ## ===============================================================================================

  alias SrpcWorld.Lights

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  ## ===============================================================================================
  ##
  ##  Routes
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Say aloha to name provided in query string.
  ## -----------------------------------------------------------------------------------------------
  get "/hello" do
    conn = fetch_query_params(conn)
    name = conn.query_params |> Map.get("name") || ""
    respond(conn, {:text, "Aloha #{name}"})
  end

  ## -----------------------------------------------------------------------------------------------
  #   Map representing the status of the SrpcWorld lights
  ## -----------------------------------------------------------------------------------------------
  get "/status" do
    case Lights.status() do
      {:ok, status} ->
        respond(conn, {:json, status |> Poison.encode!()})

      {:error, reason} ->
        respond(conn, {:text, reason})
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Reverse request data 
  ## -----------------------------------------------------------------------------------------------
  post "/reverse" do
    reversed =
      conn
      |> req_body
      |> reverse_binary

    respond(conn, {:data, reversed})
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Perform action on lights and return resulting status
  ## -----------------------------------------------------------------------------------------------
  post "/action" do
    conn
    |> req_body
    |> Poison.decode()
    |> case do
      {:ok, command} ->
        case action(command["action"], command["light"]) do
          {:ok, status} ->
            respond(conn, {:json, status |> Poison.encode!()})

          error ->
            respond(conn, error)
        end

      error ->
        respond(conn, error)
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Catch all for no route
  ## -----------------------------------------------------------------------------------------------
  match _ do
    send_resp(conn, 404, "Not Found")
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Reverse binary data by bytes (not bits)
  ## -----------------------------------------------------------------------------------------------
  defp reverse_binary(data) do
    bits = :erlang.size(data) * 8
    <<x::size(bits)-integer-little>> = data
    <<x::size(bits)-integer-big>>
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Forward light action to Lights server
  ## -----------------------------------------------------------------------------------------------
  defp action("switch", light), do: Lights.switch(light)
  defp action("on", light), do: Lights.on(light)
  defp action("onf", light), do: Lights.off(light)

  ## -----------------------------------------------------------------------------------------------
  ##  Snag the request body from the conn
  ## -----------------------------------------------------------------------------------------------
  defp req_body(conn) do
    case conn.assigns[:body] do
      nil ->
        case read_body(conn) do
          {:ok, body, _conn} -> body
          _ -> throw(:invalid_body)
        end

      body ->
        body
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Respond error
  ## -----------------------------------------------------------------------------------------------
  defp respond(conn, {:error, reason}) do
    require Logger
    Logger.error("#{__MODULE__} error: #{reason}")

    conn
    |> resp_headers(:text)
    |> send_resp(400, "Bad Request")
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Respond invalid
  ## -----------------------------------------------------------------------------------------------
  defp respond(conn, {:invalid, reason}) do
    conn
    |> resp_headers(:json)
    |> send_resp(200, Poison.encode!(%{error: reason}))
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Respond 
  ## -----------------------------------------------------------------------------------------------
  defp respond(conn, {type, body}) do
    conn
    |> resp_headers(type)
    |> send_resp(200, body)
  end

  ## -----------------------------------------------------------------------------------------------
  ##  Response headers
  ## -----------------------------------------------------------------------------------------------
  defp resp_headers(conn, :text) do
    conn |> resp_headers("text/plain")
  end

  defp resp_headers(conn, :data) do
    conn |> resp_headers("application/octet-stream")
  end

  defp resp_headers(conn, :json) do
    conn |> resp_headers("application/json")
  end

  defp resp_headers(conn, content_type) do
    conn
    |> put_resp_header("server", "Srpc World Server/0.5.0")
    |> put_resp_content_type(content_type)
  end
end
