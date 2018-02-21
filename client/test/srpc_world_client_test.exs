defmodule SrpcWorldClientTest do
  use ExUnit.Case
  doctest SrpcWorldClient

  test "greets the world" do
    assert SrpcWorldClient.hello() == :world
  end
end
