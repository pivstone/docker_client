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
    opts = [:binary,packet: :line,active: false]
    Logger.debug "connect to #{address}"
    :gen_tcp.connect({:local,address}, 0, opts)
  end


  def containers(pid) do
    GenServer.call(pid,{:get,"/containers/json"})
  end



  @doc """
  处理 GET 请求
  """
  def handle_call({:get,url},_, socket) do
    data = "GET #{url || "/"} HTTP/1.1\r\nHost: var.run.docker\r\n\r\n"
    Logger.debug "HTTP request header:#{data}"
    :ok = :gen_tcp.send(socket,data)
    response = handle_header(socket,%Docker.Response{})
    {:reply, response, socket}
  end


  defp handle_header(socket,response) do
    {:ok,binary} = :gen_tcp.recv(socket, 0,3000)
    Logger.debug binary
    cond do
        String.starts_with?(binary,"HTTP/1.1") ->
          status_code = Regex.named_captures(~r/HTTP\/1.1 (?<status_code>\d+)/, binary)
          response = Map.put(response, :status_code, String.to_integer( status_code["status_code"]))
          handle_header(socket,response)

        String.starts_with?(binary,"\r\n") ->
          handle_body(socket,response)

        true ->
          [key,value] = String.split(binary,":", parts: 2)
          response = Map.put(response,:headers,Map.put(response.headers, String.to_atom(key), value))
          IO.inspect response.headers
          handle_header(socket,response)
      end
  end

  defp handle_body(socket,response,line_num \\ 0) do
    {:ok, binary} = :gen_tcp.recv(socket,0)
    Logger.debug binary
    if :chunked in response.headers do
       if binary== "0\r\n" do
          IO.puts "over"
          response
        else
          if rem(line_num,2) == 0 do
              handle_body(socket,response,line_num+1)
          else
            body = response.body<>binary
            response = Map.put(response,:body,body )
            handle_body(socket,response,line_num+1)
          end
        end
    else
      body = response.body<>binary
      Map.put(response,:body,body )
    end
  end

  defp process_response(data) do
       case data do
         {:ok,content} ->
           Logger.debug "Response content:#{content}"
           [ headers | body ]= String.split(content,"\r\n\r\n")
           status_code = Regex.named_captures(~r/HTTP\/1.1 (?<status_code>\d+)/, headers)
           Map.put( %Docker.Response {}, :status_code, String.to_integer( status_code["status_code"]))
           |> Map.put(:body, Poison.decode!(body))
         {:error,reason} ->
           IO.puts reason
       end
  end
end
