defmodule Docker.Response do
  @moduledoc """
  TCP Response 主要负责读取和解析 HTTP Response
  """
  require Logger
  defstruct code: 404,
            body: <<"">>,
            headers: Map.new,
            chunked: false,
            len: 0

  defimpl Inspect, for: Docker.Response do
    @doc """
    格式化展示
    """
    def inspect(%Docker.Response{}=resp,_) do
      """
      Response<
        code: #{resp.code}
        headers: #{inspect resp.headers}
        body: #{inspect resp.body}
        len:#{resp.len}
        chunked:#{resp.chunked}
      >
      """
    end
  end

  @doc ~S"""
  参照 HTTP 协议处理 HTTP的返回头
  """
  def handle_header(socket,resp)  do
    {:ok,bin} = :gen_tcp.recv(socket, 0,3000)
    Logger.debug bin
    cond do
        String.starts_with?(bin,"HTTP/1.1") ->  # 处理 Http Status Code
          code = Regex.named_captures(~r/HTTP\/1.1 (?<code>\d+)/, bin)
          resp = Map.put(resp, :code, code["code"]|>String.to_integer)
          handle_header(socket,resp)

        String.starts_with?(bin,"\r\n") ->  # 遇到单独一行这个，说明数据已经结束了了
          parse_header(resp)

        true ->
          [key,value] = String.split(bin,":", parts: 2)# 拆封 headers 成 key/value ，说明数据已经总结了
          resp = Map.put(resp,:headers,Map.put(resp.headers,key|>String.to_atom, value|>String.strip))
          handle_header(socket,resp)
      end
  end

  defp parse_header(resp) do
    # 转换一下 raw_header
    # 将 Content-Length 更新到 Response 中去
    resp =
      if Map.has_key?(resp.headers, :"Content-Length") do
        len = resp.headers[:"Content-Length"]|>String.to_integer
        Map.put(resp,:len,resp.len+len)
      else
        resp
      end
    # 检查下是否为 chunked 的数据类型
    if Map.has_key?(resp.headers, :"Transfer-Encoding") ,do: Map.put(resp,:chunked, true), else: resp
  end

  # chunked 数据 偶数行为 Chunked length
  defp parse_body(socket,resp,bin,ln)  when rem(ln,2) == 0 do
    len = String.to_integer(String.strip(bin),16)
    resp = Map.put(resp,:len,resp.len+len)
    handle_body(socket,resp,ln+1)
  end

  # 奇数行为实际数据，需要处理
  defp parse_body(socket,resp,bin,l_n)  when rem(l_n,2) != 0  do
    body = resp.body<>bin
    resp = Map.put(resp,:body,body)
    # 由于可能出现一次 recv 未能传输完成所有数据的情况，
    # 需要判定收到的数据是否小于 Content-Length
    # 小于的话 继续获取数据
    if String.length(resp.body) < resp.len do
       handle_body(socket,resp,l_n)
    else
      handle_body(socket,resp,l_n+1)
    end
  end


  # 处理非 chunked 的数据
  def handle_body(socket, %Docker.Response{:chunked => false} = resp,ln) do
    {:ok, bin} = :gen_tcp.recv(socket,0)
    Logger.debug bin
    body = resp.body<>bin
    resp = Map.put(resp,:body,body)
    # 由于可能出现一次 recv 未能传输完成所有数据的情况，
    # 需要判定收到的数据是否小于 Content-Length
    # 小于的话 继续获取数据
    if String.length(resp.body) < resp.len do
       handle_body(socket,resp,ln)
    else
      Map.put(resp,:body, Poison.decode!(resp.body))
    end
  end
  def handle_body(socket,%Docker.Response{:chunked => true} = resp,l_n) do
   {:ok, bin} = :gen_tcp.recv(socket,0)
   Logger.debug "#{bin}"
   cond do
      # Chunked 传输的结束符号为 "0\r\n"
      # refs:https://en.wikipedia.org/wiki/Chunked_transfer_encoding
      bin == "0\r\n" ->
        Logger.debug "over"
        Logger.debug resp.body
        Map.put(resp,:body, Poison.decode!(resp.body))
      # 空行数据的话 跳过
      bin == "\r\n" ->
        handle_body(socket,resp,l_n)
      true ->
        parse_body(socket,resp,bin,l_n)
    end
  end

  def handle_body(socket,%Docker.Response{:chunked => true} = resp,l_n,pid) do
   {:ok, bin} = :gen_tcp.recv(socket,0)
   Logger.debug "steam #{bin}"
   cond do
      # Chunked 传输的结束符号为 "0\r\n"
      # refs:https://en.wikipedia.org/wiki/Chunked_transfer_encoding
      bin == "0\r\n" ->
        Logger.debug "over"
        Logger.debug resp.body
      # 空行数据的话 跳过
      bin == "\r\n" ->
        handle_body(socket,resp,l_n,pid)
      true ->
        if rem(l_n,2) == 0 do
          len = String.to_integer(String.strip(bin),16)
          resp = Map.put(resp,:len,len)
          handle_body(socket,resp,l_n+1,pid)
        else
          body = resp.body<>bin
          resp = Map.put(resp,:body,body)
          # 由于可能出现一次 recv 未能传输完成所有数据的情况，
          # 需要判定收到的数据是否小于 Content-Length
          # 小于的话 继续获取数据
          if String.length(resp.body) < resp.len do
             handle_body(socket,resp,l_n,pid)
          else
            send pid ,{:ok,resp.body}
            resp = Map.put(resp,:body,<<"">>)
            handle_body(socket,resp,l_n+1,pid)
          end
        end
    end
  end
end
