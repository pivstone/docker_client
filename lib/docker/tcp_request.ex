defmodule Docker.TcpRequest do
  @moduledoc """

  TCP Request 主要负责发起 HTTP Request
  """
  require Logger

  defp init(url) do
    # 因为 HTTP Protocol 的关系用 line 来recv 比较舒服
    case url do
        "unix://"<>path ->
          opts = [:binary,packet: :line,active: false]
          :gen_tcp.connect({:local,path}, 0, opts)
        "http://"<>_ ->
          uri = URI.parse(url)
          opts = [:binary,packet: :line,active: false]
          :gen_tcp.connect(to_charlist(uri.host),uri.port,opts)
      end
  end


  def send_request(socket,url,method \\ "GET",data\\nil) do
    host =
      case url do
        "unix://"<>_ -> "var.run.docker"
        "http://"<>_ -> URI.parse(url).host
      end

    data_string = "#{method} #{url || "/"} HTTP/1.1\r\nHost: #{host}\r\n"
    data_string =
      if data do
        data_string <>"Content-Type: application/json\r\n"
                    <>"Content-Length: #{String.length(data)}\r\n\r\n"
                    <>"#{data}"
      else
        data_string<>"\r\n"
      end
    Logger.debug data_string
    :ok = :gen_tcp.send(socket,data_string)
  end
  @doc """
  非 Keep-Alive 的请求
  """
  def request({:get,url},addr) do
    target_url = URI.merge(URI.parse(addr), url)|> to_string
    {:ok,socket} = init(target_url)
    send_request(socket,target_url)
    parse_response(socket)
  end

  defp parse_response(socket) do
    resp = Docker.TcpResponse.handle_header(socket,%Docker.TcpResponse{})
    resp = Docker.TcpResponse.handle_body(socket,resp,0)

    # HTTP 中 Socket 不复用,需要关闭
    :gen_tcp.close(socket)
    {:ok, resp}
  end

  def request({:post,url},addr,params,data) do
    target_url =
      case is_nil(params) do
       false -> URI.merge(URI.parse(addr), url)|> URI.merge(params)
                 |> to_string
       true -> URI.merge(URI.parse(addr), url)
                 |> to_string
      end
    {:ok,socket} = init(target_url)
    send_request(socket,target_url,"POST",data)
    parse_response(socket)
  end

  @doc """
  Keep Alive steam request

  *注意* 流中断之后，要客户端重新连接，中断期间的数据不会重发
  """
  def request({:get,url},addr,pid) do
    target_url = URI.merge(URI.parse(addr), url)|> to_string
    {:ok,socket} = init(target_url)
    send_request(socket,target_url)
    Task.start_link(fn ->
      resp = Docker.TcpResponse.handle_header(socket,%Docker.TcpResponse{})
      resp = Docker.TcpResponse.handle_body(socket,resp,0,pid)

      # HTTP 中 Socket 不复用,需要关闭
      :gen_tcp.close(socket)
      {:ok, resp}
    end)
  end
end
