defmodule Docker.Mixfile do
  use Mix.Project

  def project do
    [app: :docker_client,
     version: "0.2.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     name: "docker_client",
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     source_url: "https://github.com/pivstone/docker-us-connector",
     docs: [main: "readme", # The main page in the docs
          extras: ["README.md"]]
     ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison, "~> 2.2"},
      {:ex_doc, "~> 0.14", only: :dev},
      {:excoveralls, "~> 0.5", only: :test},
      {:meck, "~> 0.8.4", only: :test}
    ]
  end

  def description do
    """
    A Docker client via Unix socket .
    """
  end

  def package do
    [# These are the default files included in the package
     name: :docker_client,
     files: ["lib", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     maintainers: ["pivstone@gmail.com"],
     licenses: ["MIT licenses"],
     links: %{"GitHub" => "https://github.com/pivstone/docker_client",
              "Docs" => "https://pivstone.github.io/docker_client"}]
  end
end
