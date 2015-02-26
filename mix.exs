defmodule Mix.Tasks.Compile.NetManagers do
  @shortdoc "Compiles the port binary"
  def run(_) do
    0=Mix.Shell.IO.cmd("make priv/udhcpc_wrapper")
  end
end

defmodule NetManagers.Mixfile do
  use Mix.Project

  def project do
    [app: :net_managers,
     version: "0.0.1",
     elixir: "~> 1.0.0",
	 compilers: [:NetManagers, :elixir, :app],
     deps: deps,
     package: package,
     description: description
	]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :net_basic, :wpa_supplicant]]
  end

  defp description do
    """
    Test of IP network configuration.
    """
  end

  defp package do
    %{files: ["lib", "src/*.[ch]", "test", "mix.exs", "README.md", "LICENSE", "Makefile"],
      contributors: ["Frank Hunleth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/fhunleth/net_managers.ex"}}
  end

  # Dependencies can be hex.pm packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:net_basic, github: "fhunleth/net_basic.ex", tag: "master"},
      {:wpa_supplicant, github: "fhunleth/wpa_supplicant.ex", tag: "master"}
    ]
  end
end
