defmodule DockerTest do
  use ExUnit.Case, async: true
  doctest Docker


  setup %{} do
    :meck.new(:gen_tcp, [:unstick])
    :meck.expect(:gen_tcp,:connect,fn(_,_,_) -> {:ok,"socket"} end)
    :meck.expect(:gen_tcp,:send,fn(_,_) -> :ok end)
    config = Docker.config("http://10.9.8.110:11111")
    {:ok, config: config}
  end

  test "GET containers list",%{config: config} do

    {:ok,pid} = MockServer.start_link("test/data/containers/json.data","@")
    :meck.expect(:gen_tcp,:recv,fn(_,_,_)-> {:ok,MockServer.recv(pid)} end)
    :meck.expect(:gen_tcp,:recv,fn(_,_)-> {:ok,MockServer.recv(pid)} end)
    :meck.expect(:gen_tcp,:close,fn(_) -> {:ok} end)
    {:ok,resp} = Docker.containers(config)
    assert resp.code==200
  end
"""
  test "Create containers ",%{config: config} do
    {:ok,resp}  = Docker.create_container(config,%{"Image" => "registry:2"})
    IO.inspect resp
    assert resp.code==201
  end

  test "Start Containers" ,%{config: config} do
    {:ok,resp} = Docker.start_container(config,"1a5e3c8fdc77")
    assert resp.code==204
  end

  test "Stop Containers" ,%{config: config} do
    {:ok,resp} = Docker.stop_container(config,"1a5e3c8fdc77")
    assert resp.code==204
  end

  test "Inspect Containers" ,%{config: config} do
    {:ok,resp} = Docker.inspect_container(config,"bef3f3b117e5")
    assert resp.code==200
  end
  """


end
