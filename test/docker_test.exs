defmodule DockerTest do
  use ExUnit.Case, async: true
  doctest Docker


  def mock(path) do
    :meck.new(:gen_tcp, [:unstick,:passthrough])
    :meck.expect(:gen_tcp,:connect,fn(_,_,_) -> {:ok,"socket"} end)
    :meck.expect(:gen_tcp,:send,fn(_,_) -> :ok end)
    {:ok,pid} = MockServer.start_link(path,"@")
    :meck.expect(:gen_tcp,:recv,fn(_,_,_)-> {:ok,MockServer.recv(pid)} end)
    :meck.expect(:gen_tcp,:recv,fn(_,_)-> {:ok,MockServer.recv(pid)} end)
    :meck.expect(:gen_tcp,:close,fn(_) -> {:ok} end)
  end

  setup %{} do
    config = Docker.config("http://10.9.8.110:11111")
    {:ok, config: config}
  end

  test "GET containers list",%{config: config} do

    mock("test/data/containers/json.data")
    {:ok,resp} = Docker.containers(config)
    assert resp.code==200
    :meck.unload(:gen_tcp)
  end

  test "Inspect Containers" ,%{config: config} do
    mock("test/data/containers/760c0e4240c7.data")
    {:ok,resp} = Docker.container(config,"ccb46930869e")
    assert resp.code==200
    :meck.unload(:gen_tcp)
  end

end
