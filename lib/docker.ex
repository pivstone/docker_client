defmodule Docker do
  @moduledoc ~S"""

  Docker Client

  docker engine 通过绑定 unix sockets 来对外暴露 Remote API

  其本质是在 unix sockets 上进行 HTTP 协议的传输

  """
  require Logger

  defstruct addr: "",
            req: &Docker.TcpRequest.request/2

  @doc ~S"""

  设置容器连接信息

  ## Examples

    iex > config = Docker.config("unix:///var/run/docker.sock")

  """
  def config(addr \\ "unix:///var/run/docker.sock") do
      Map.put(%Docker{},:addr, addr)
  end


  @doc ~S"""
  获取容器列表.

  ## Examples

    iex > config = Docker.config(address)
    iex > Docker.containers(config)
  """
  def containers(docker) do
    docker.req.({:get,"/containers/json"},docker.addr)
  end

  @doc ~S"""
  获取镜像列表.

  ## Examples

    iex > config = Docker.config(address)
    iex > Docker.images(config)
  """
  def images(docker) do
    docker.req.({:get,"/images/json"},docker.addr)
  end

  @doc ~S"""
  获取 Docker Info.

  ## Examples

    iex > config = Docker.config(address)
    iex > Docker.info(config)
  """
  def info(docker) do
    docker.req.({:get,"/info"},docker.addr)
  end

  @doc ~S"""
  获取 Docker 版本信息.

  ## Examples

    iex > config = Docker.config(address)
    iex > Docker.info(config)
  """
  def version(docker) do
    docker.req.({:get,"/version"},docker.addr)
  end

  def volumes(docker) do
    docker.req.({:get,"/volumes"},docker.addr)
  end

  @doc ~S"""
  添加 Docker Event 监听器.

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
  config = Docker.config(address)
  Docker.add_event_listener(config,spawn(Example, :listen, []))
  ```
  """
  def add_event_listener(docker,pid \\self) do
    docker = Map.put(docker,:req, &Docker.TcpRequest.request/3)
    docker.req.({:get,"/events"},docker.addr,pid)
  end


  @doc ~S"""
  添加 Docker Log 监听器.

  ## Examples
  ```elixir
  config = Docker.config(address)
  Docker.add_event_listener(config,container_id)
  ```
  """
  def add_log_listener(docker,container_id,pid\\self) do
    Docker.TcpRequest.request({:get,"/containers/#{container_id}/logs"},docker.addr,pid)
  end

  @doc ~S"""
  创建 Docker 容器

  ## Examples
  ```elixir
  config = Docker.config(address)
  {:ok,resp} = Docker.create_container(config,%{"Image" => "registry:2"})
  assert resp.code == 201
  ```
  """
  def create_container(docker,data) do
    data_string = Poison.encode!(data)
    Docker.TcpRequest.request({:post,"/containers/create"},docker.addr,nil,data_string)
  end
end
