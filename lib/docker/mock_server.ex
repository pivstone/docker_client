defmodule MockServer do
  use GenServer

  def start_link(path,flag,opts\\[]) do
    data = File.read!(path)
          |>String.replace(~s"\n",~s"\r\n")
          |>String.split(flag)
    GenServer.start_link(__MODULE__,data,opts)
  end

  def recv(pid) do
    GenServer.call(pid, :recv)
  end

  def handle_call(:recv,_from, [h|t]=state)do
    {:reply, h, t}
  end
end
