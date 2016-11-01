defmodule Docker do
  @moduledoc ~S"""

  Docker Client

  docker engine 通过绑定 unix sockets 来对外暴露 Remote API

  其本质是在 unix sockets 上进行 HTTP 协议的传输

  """
  require Logger

  defstruct addr: "",
            req: &Docker.Request.get/2

  @doc ~S"""

  设置容器连接信息

  ## Examples
  ```elixir
    iex > config = Docker.config("unix:///var/run/docker.sock")
    iex > config = Docker.config("http://192.168.0.1:12450")
  ```
  """
  def config(addr \\ "unix:///var/run/docker.sock") do
      Map.put(%Docker{},:addr, addr)
  end


  @doc ~S"""
  获取容器列表.

  ## Examples
  ```elixir
    iex > config = Docker.config(address)
    iex > Docker.containers(config)
  ```
  """
  def containers(docker), do: docker.req.("/containers/json?all=true",docker.addr)

  @doc ~S"""
  获取镜像列表.

  ## Examples
  ```elixir
    iex > config = Docker.config(address)
    iex > Docker.images(config)
  ```
  """
  def images(docker), do: docker.req.("/images/json",docker.addr)

  @doc ~S"""
  获取 Docker Info.

  ## Examples
  ```elixir
    iex > config = Docker.config(address)
    iex > Docker.info(config)
  ```
  """
  def info(docker), do: docker.req.("/info",docker.addr)

  @doc ~S"""
  获取 Docker 版本信息.

  ## Examples
  ```elixir
    iex > config = Docker.config(address)
    iex > Docker.info(config)
  ```
  """
  def version(docker) ,do: docker.req.("/version",docker.addr)

  @doc """
  获取 Volumes 列表
  """
  def volumes(docker) ,do: docker.req.("/volumes",docker.addr)

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
    Docker.Request.get("/events",docker.addr,pid)
  end

  @doc ~S"""
  添加 Docker Log 监听器.

  ## Examples
  ```elixir
  config = Docker.config(address)
  Docker.add_event_listener(config,container_id)
  ```
  """
  def add_log_listener(docker,id,pid\\self) do
    Docker.Request.get("/containers/#{id}/logs",docker.addr,pid)
  end

  @doc ~S"""
  创建 Docker 容器

  ## Examples
  ```elixir
  config = Docker.config(address)
  {:ok,resp} = Docker.create_container(config,%{"Image" => "registry:2"})
  assert resp.code == 201
  ```
  具体参数参考 (Docker Remote API)[https://docs.docker.com/engine/reference/api/docker_remote_api_v1.24/#/create-a-container]
  """
  def create_container(docker,data) do
    data_string = Poison.encode!(data)
    Docker.Request.post("/containers/create",docker.addr,data_string)
  end

  @doc ~S"""
  CN:启动容器
  EN:Start a container¶
  ## Examples
  ```elixir
  config = Docker.config(address)
  {:ok,resp} = Docker.start(config,"containerId")
  """
  def start(docker,id) do
    Docker.Request.post("/containers/#{id}/start",docker.addr)
  end
  @doc """
  CN:停止容器
  EN:Stop a container¶
  ## Examples
  ```elixir
  config = Docker.config(address)
  {:ok,resp} = Docker.stop(config,"containerId")
  """
  def stop(docker,id) do
     Docker.Request.post("/containers/#{id}/stop",docker.addr)
  end

  @doc ~S"""
  CN:获取指定容器ID的信息
  EN:Inspect a container
  """
  def container(docker,id) do
   docker.req.("/containers/#{id}/json",docker.addr)
  end

  @doc ~S"""
  CN:列出容器中所有的进程信息
  EN:List processes running inside a container
  """
  def top(docker,id), do: docker.req.("/containers/#{id}/top",docker.addr)

  @doc ~S"""
  CN:列出容器中的资源状态
  EN:Get container stats based on resource usage
  """
  def stats(docker,id), do: docker.req.("/containers/#{id}/stats",docker.addr)

  @doc ~S"""
  CN:列出容器文件系统的变更
  EN:Inspect changes on a container’s filesystem
  """
  def changes(docker,id), do: docker.req.("/containers/#{id}/changes",docker.addr)
  @doc ~S"""
  CN:强制关闭容器
  EN:Kill a container
  """
  def kill(docker,id), do: docker.req.("/containers/#{id}/kill",docker.addr)
end
