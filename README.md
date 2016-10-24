# Docker Client


Support:


HTTP / Unix Socket


*NOTE*


HTTPS(TLS) not Supported!

Only Erlang 19 Support(Experimental)unix sockets

## Status

Just a demo

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `docker_client` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:docker_us_connector, "~> 0.1.0"}]
    end
    ```

  2. Ensure `docker_client` is started before your application:

    ```elixir
    def application do
      [applications: [:docker_client]]
    end
    ```


## Usage

```elixir
iex> config = Docker.config()
iex> Docker.containers(config)
[%{"Command" => "nginx -g 'daemon off;'", "Created" => 1476779504,
   "HostConfig" => %{"NetworkMode" => "default"},
   "Id" => "ccb46930869ea70f55fae0f29904a96651c59635e5bb905bfe9c5da9ed2a7021",
   "Image" => "nginx",
   "ImageID" => "sha256:ba6bed934df2e644fdd34e9d324c80f3c615544ee9a93e4ce3cfddfcf84bdbc2",
   "Labels" => %{}, "Mounts" => [], "Names" => ["/hungry_fermat"],
   "NetworkSettings" => %{"Networks" => %{"bridge" => %{"Aliases" => nil,
         "EndpointID" => "41abb0b3e7ac420ce7c2b27fd7f45361402f223d8e7f9194219409498ec6e68c",
         "Gateway" => "172.17.0.1", "GlobalIPv6Address" => "",
         "GlobalIPv6PrefixLen" => 0, "IPAMConfig" => nil,
         "IPAddress" => "172.17.0.2", "IPPrefixLen" => 16, "IPv6Gateway" => "",
         "Links" => nil, "MacAddress" => "02:42:ac:11:00:02",
         "NetworkID" => "7486e5689b83e3bed92ae17c6ccce025007cb2262a031e3b06e2bd17784bfdae"}}},
   "Ports" => [%{"PrivatePort" => 443, "Type" => "tcp"},
    %{"PrivatePort" => 80, "Type" => "tcp"}], "State" => "running",
   "Status" => "Up 59 seconds"}]
```
