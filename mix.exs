defmodule Mix.Tasks.Compile.NetManagers do
  @shortdoc "Compiles the port binary"
  def run(_) do
    {result, _error_code} = System.cmd("make", ["priv/udhcpc_wrapper"], stderr_to_stdout: true)
    IO.binwrite result
    Mix.Project.build_structure
  end
end

defmodule NetManagers.Mixfile do
  use Mix.Project

  def project do
    [app: :net_managers,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: Mix.compilers ++ [:NetManagers],
     deps: deps,
     docs: [extras: ["README.md"]],
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

  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:net_basic, github: "fhunleth/net_basic.ex", tag: "master"},
      {:wpa_supplicant, github: "fhunleth/wpa_supplicant.ex", tag: "master"}
    ]
  end
end
