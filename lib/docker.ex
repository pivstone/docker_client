defmodule Docker do
  @moduledoc """
  Docker Client via Unix Sockets
  docker engine 通过绑定 unix sockets 来对外暴露操作 API
  其本质是在 unix sockets 上进行 HTTP 协议的传输
  """
  require Logger

  defstruct addr: "/var/run/docker.sock",
            req: &Docker.TcpRequest.request/2


  def conn() do
      %Docker{}
  end

  def conn(addr) do
      Map.put(%Docker{},:addr, addr)
  end


  @doc ~S"""
  获取容器列表.

  ## Examples

    iex > conn = Docker.conn(address)
    iex > Docker.containers(conn)
  """
  def containers(docker) do
    {:ok, resp} = docker.req.({:get,"/containers/json"},docker.addr)
    resp.body
  end

  @doc ~S"""
  获取镜像列表.

  ## Examples

    iex > conn = Docker.conn(address)
    iex > Docker.images(conn)
  """
  def images(docker) do
    {:ok, resp}=docker.req.({:get,"/images/json"},docker.addr)
    resp.body
  end

  @doc ~S"""
  获取 Docker Info.

  ## Examples

    iex > conn = Docker.conn(address)
    iex > Docker.info(conn)
  """
  def info(docker) do
    {:ok, resp}=docker.req.({:get,"/info"},docker.addr)
    resp.body
  end

  @doc ~S"""
  获取 Docker 版本信息.

  ## Examples

    iex > conn = Docker.conn(address)
    iex > Docker.info(conn)
  """
  def version(docker) do
    {:ok, resp}=docker.req.({:get,"/version"},docker.addr)
    resp.body
  end

  def volumes(docker) do
    {:ok, resp}=docker.req.({:get,"/volumes"},docker.addr)
    resp.body
  end

  @doc ~S"""
  获取 Docker 版本信息.

  ## Examples
  ```elixir
  defmodule Example do
    def listen do
      receive do
        {:ok, _ } -> IO.puts "World"
      end
      listen
    end
  end
  conn = Docker.conn(address)
  Docker.add_event_listener(conn,spawn(Example, :listen, []))
  ```
  """
  def add_event_listener(docker,pid) do
    docker = Map.put(docker,:req, &Docker.TcpRequest.request/3)
    docker.req.({:get,"/events"},docker.addr,pid)
  end
end
