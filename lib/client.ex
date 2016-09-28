defmodule Docker.Client do
  use GenServer
  require Logger

  @doc """
  连接 Docker
  """
  def start_link(address \\ "/var/run/docker.sock") do
    GenServer.start_link(__MODULE__,address)
  end

  def init(address) do
   {:ok, address}
  end

  def containers(pid) do
    GenServer.call(pid,{:get,"/containers/json"})
  end

  @doc """
  处理 GET 请求
  """
  def handle_call({:get,url},_,address \\ "/var/run/docker.sock") do
    Logger.debug "connect to #{address}"
    opts = [:binary,packet: :line,active: false]
    {:ok,socket} = :gen_tcp.connect({:local,address}, 0, opts)
    data = "GET #{url || "/"} HTTP/1.1\r\nHost: var.run.docker\r\n\r\n"
    Logger.debug "HTTP request header:#{data}"
    :ok = :gen_tcp.send(socket,data)
    response = handle_header(socket,%Docker.Response{})
    :gen_tcp.close(socket)
    {:reply, response,address}
  end

  # 处理headers
  defp handle_header(socket,response)  do
    {:ok,binary} = :gen_tcp.recv(socket, 0,3000)
    Logger.debug binary
    cond do
        String.starts_with?(binary,"HTTP/1.1") ->  # 处理 Http Status Code
          status_code = Regex.named_captures(~r/HTTP\/1.1 (?<status_code>\d+)/, binary)
          response = Map.put(response, :status_code, status_code["status_code"]|>String.to_integer)
          handle_header(socket,response)

        String.starts_with?(binary,"\r\n") ->  # 遇到单独一行这个，说明数据已经总结了
          parse_header(socket,response)

        true ->
          [key,value] = String.split(binary,":", parts: 2)# 拆封 headers 成 key/value ，说明数据已经总结了
          response = Map.put(response,:headers,Map.put(response.headers,key|>String.to_atom, value|>String.strip))
          handle_header(socket,response)
      end
  end

  defp parse_header(socket,response) do
    # 转换一下 raw_header
    # 将 Content-Length 更新到 Response 中去
    response = if Map.has_key?(response.headers, :"Content-Length") do
      length = response.headers[:"Content-Length"]|>String.to_integer
      Map.put(response,:length,response.length+length)
    else
      response
    end
    # 检查下是否为 chunked 的数据类型
    response = if Map.has_key?(response.headers, :"Transfer-Encoding") ,do: Map.put(response,:chunked, true), else: response
    handle_body(socket,response,0)
  end

  # chunked 数据 偶数行为 Chunked length，暂不处理
  defp parse_body(socket,response,binary,line_num)  when rem(line_num,2) == 0 do
    length = String.to_integer(String.strip(binary),16)
    response = Map.put(response,:length,response.length+length)
    handle_body(socket,response,line_num+1)
  end

  # 奇数行为实际数据，需要处理
  defp parse_body(socket,response,binary,line_num)  when rem(line_num,2) != 0 do
    body = response.body<>binary
    response = Map.put(response,:body,body)
    if String.length(response.body) < response.length do
       handle_body(socket,response,line_num)
    else
      handle_body(socket,response,line_num+1)
    end
  end

  # 处理非 chunked 的数据
  defp handle_body(socket, %Docker.Response{:chunked => false} =response,line_num) do
    {:ok, binary} = :gen_tcp.recv(socket,0)
    Logger.debug binary
    body = response.body<>binary
    response = Map.put(response,:body,body)
    if String.length(response.body) < response.length do
       handle_body(socket,response,line_num)
    else
      Map.put(response,:body, Poison.decode!(response.body))
    end
  end

  defp handle_body(socket,%Docker.Response{:chunked => true}=response,line_num) do
    {:ok, binary} = :gen_tcp.recv(socket,0)
    Logger.debug "#{binary}"
    cond do
       binary== "0\r\n" ->
         Logger.debug "over"
         Logger.debug response.body
         Map.put(response,:body, Poison.decode!(response.body))
       binary== "\r\n" ->
         handle_body(socket,response,line_num+1)
       true ->
         parse_body(socket,response,binary,line_num)
     end
   end
end
