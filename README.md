# Docker Client via Unix Sockets


*Need Erlang 19*

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
