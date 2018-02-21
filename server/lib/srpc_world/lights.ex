defmodule SrpcWorld.Lights do
  @moduledoc """
  Simple on/off control of a set of lights
  """

  ## ===============================================================================================
  ##
  ##  Module constants
  ##
  ## ===============================================================================================
  @default_lights ["red", "yellow", "green"]

  ## ===============================================================================================
  ##
  ##  SrpWorld Lights GenServer
  ##
  ##  Control on/off state of a set of lights. The GenServer state maintains a map of the lights
  ##  associated with either :on or :off
  ##
  ## ===============================================================================================
  use GenServer

  ## ===============================================================================================
  ##
  ## Client
  ##
  ## ===============================================================================================
  @doc """
  Supervisor child spec 
  """
  def child_spec(_) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [[]]}}
  end

  @doc """
  Start with default or specified list of lights
  """
  def start_link([]), do: start_link(@default_lights)
  def start_link(lights), do: GenServer.start_link(__MODULE__, lights, name: __MODULE__)

  @doc """
  Initialize application with list of lights, all turned `off`
  """
  def init(lights) when is_list(lights) do
    if List.foldl(lights, true, fn light, acc -> acc and is_binary(light) end) do
      {:ok, List.foldl(lights, %{}, fn light, map -> Map.put(map, light, :off) end)}
    else
      {:stop, "Invalid list of lights"}
    end
  end

  ## ===============================================================================================
  ##
  ##  Public API
  ##
  ## ===============================================================================================
  @doc """
  Status of lights as a map of `light` associated to either `on` or `off`
  """
  def status, do: GenServer.call(__MODULE__, :status)

  @doc """
  Switch lights so that only `light` is `on`
  """
  def switch(light), do: GenServer.call(__MODULE__, {:switch, light})

  @doc """
  Turn `light` `on`
  """
  def on(light), do: GenServer.call(__MODULE__, {:on, light})

  @doc """
  Turn `light` `off`
  """
  def off(light), do: GenServer.call(__MODULE__, {:off, light})

  ## ===============================================================================================
  ##
  ##  GenServer Calls
  ##
  ## ===============================================================================================
  @doc """
  Handle `GenServer` callbacks
  """
  def handle_call(:status, _from, lights), do: {:reply, {:ok, lights}, lights}

  def handle_call({:switch, light}, _from, lights) do
    lights |> lights_off |> turn(light, &on/2)
  end

  def handle_call({:on, light}, _from, lights) do
    lights |> turn(light, &on/2)
  end

  def handle_call({:off, light}, _from, lights) do
    lights |> turn(light, &off/2)
  end

  ## ===============================================================================================
  ##
  ##  Private
  ##
  ## ===============================================================================================
  ## -----------------------------------------------------------------------------------------------
  ##  Map with all lights off
  ## -----------------------------------------------------------------------------------------------
  defp lights_off(lights) do
    lights |> Map.keys() |> List.foldl(%{}, fn light, map -> Map.put(map, light, :off) end)
  end

  ## -----------------------------------------------------------------------------------------------
  ##  If lights contains light, reply by executing fun; otherwise reply invalid
  ## -----------------------------------------------------------------------------------------------
  defp turn(lights, light, fun) do
    if lights |> Map.has_key?(light) do
      lights = lights |> fun.(light)
      {:reply, {:ok, lights}, lights}
    else
      {:reply, invalid(light), lights}
    end
  end

  ## -----------------------------------------------------------------------------------------------
  ##   Turn light on
  ## -----------------------------------------------------------------------------------------------
  defp on(lights, light), do: lights |> Map.put(light, :on)

  ## -----------------------------------------------------------------------------------------------
  ##   Turn light off
  ## -----------------------------------------------------------------------------------------------
  defp off(lights, light), do: lights |> Map.put(light, :off)

  ## -----------------------------------------------------------------------------------------------
  ##   Reply for invalid light
  ## -----------------------------------------------------------------------------------------------
  defp invalid(light) when is_binary(light), do: {:invalid, "Invalid light: #{light}"}
  defp invalid(light), do: {:invalid, "Invalid light: #{inspect(light)}"}
end
