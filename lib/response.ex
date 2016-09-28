defmodule Docker.Response do
  defstruct status_code: 404,
            body: <<"">>,
            headers: Map.new,
            chunked: false,
            length: 0
end

defimpl Inspect, for: Docker.Response do
  @doc """
  格式化展示
  """
  def inspect(%Docker.Response{}=response,_) do
    """
    Response<
      status_code: #{response.status_code}
      headers: #{inspect response.headers}
      body: #{inspect response.body}
      length:#{response.length}
      chunked:#{response.chunked}
    >
    """
  end
end
