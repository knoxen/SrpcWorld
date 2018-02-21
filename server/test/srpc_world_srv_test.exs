defmodule SrpcWorldServerTest do
  use ExUnit.Case
  doctest SrpcWorldServer

  test "greets the world" do
    assert SrpcWorldServer.hello() == :world
  end
end
