defmodule Docker.Response do
  defstruct status_code: 404,
            body: <<"">>,
            headers:  Map.new
end

defimpl Inspect, for: Docker.Response do
  @doc """
  格式化展示
  """
  def inspect(%Docker.Response{status_code: status_code,body: body,headers: headers,},_) do
    """
    Response<
      status_code: #{status_code}
      body: #{body}
      headers: #{headers}
    >
    """
  end
end
