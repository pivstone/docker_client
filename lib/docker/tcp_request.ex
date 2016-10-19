defmodule Docker.TcpRequest do
  @moduledoc """
  TCP Request
  """
  require Logger

  defp init(method \\ "GET",url,addr) do
    opts = [:binary,packet: :line,active: false]
    Logger.debug "connect to #{addr} HTTP request url:#{url}"
    {:ok,socket} = :gen_tcp.connect({:local,addr}, 0, opts)
    :ok = :gen_tcp.send(socket,"#{method} #{url || "/"} HTTP/1.1\r\nHost: var.run.docker\r\n\r\n")
    {:ok,socket}
  end

  @doc """
  normal request
  """
  def request({:get,url},addr) do
    {:ok,socket} = init(url,addr)
    resp = Docker.TcpResponse.handle_header(socket,%Docker.TcpResponse{})
    resp = Docker.TcpResponse.handle_body(socket,resp,0)
    # HTTP 中 Socket 不复用,需要关闭
    :gen_tcp.close(socket)
    {:ok, resp}
  end
  @doc """
  Keep Alive steam request
  """
  def request({:get,url},addr,pid) do
    {:ok,socket} = init(url,addr)
    Task.start_link(fn ->
      resp = Docker.TcpResponse.handle_header(socket,%Docker.TcpResponse{})
      Docker.TcpResponse.handle_body(socket,resp,0,pid)
      # HTTP 中 Socket 不复用,需要关闭
      :gen_tcp.close(socket)
    end)
  end
end
