defmodule Resolvconf do
  use GenServer

  @moduledoc """
  This module manages the contents of "/etc/resolv.conf". This file is used
  by the C library for resolving domain names and must be kept up-to-date
  as links go up and down. This module assumes exclusive ownership on
  "/etc/resolv.conf", so if any other code in the system tries to modify the
  file, their changes will be lost on the next update.
  """

  defstruct filename: nil,
            domains: %{},
            nameservers: %{}

  @resolvconf_path "/etc/resolv.conf"

  @doc """
  Return the default `resolve.conf` path for this system.
  """
  def default_resolvconf_path do
    @resolvconf_path
  end

  @doc """
  """
  def start_link(resolvconf_path \\ @resolvconf_path, opts \\ []) do
    GenServer.start_link(__MODULE__, resolvconf_path, opts)
  end

  @doc """

  """
  def configure(pid, ifname, options) do
    GenServer.call(pid, {:configure, ifname, options})
  end

  @doc """
  Set the search domain for non fully qualified domain name lookups.
  """
  def set_domain(pid, ifname, domain) do
    GenServer.call(pid, {:set_domain, ifname, domain})
  end

  @doc """
  Set the nameservers that were configured on this interface. These
  will be added to "/etc/resolv.conf" and replace any entries that
  were previously added for the specified interface.
  """
  def set_nameservers(pid, ifname, servers) when is_list(servers) do
    GenServer.call(pid, {:set_nameservers, ifname, servers})
  end

  @doc """
  Clear all entries in "/etc/resolv.conf" that are associated with
  the specified interface.
  """
  def clear(pid, ifname) do
    GenServer.call(pid, {:clear, ifname})
  end

  @doc """
  Completely clear out "/etc/resolv.conf".
  """
  def clear_all(pid) do
    GenServer.call(pid, :clear_all)
  end

  def init(filename) do
    state = %Resolvconf{filename: filename}
    write_resolvconf(state)
    {:ok, state}
  end

  def handle_call({:set_domain, ifname, domain}, _from, state) do
    newdomains = Dict.put(state.domains, ifname, domain)
    state = %{state | domains: newdomains}
    write_resolvconf(state)
    {:reply, :ok, state}
  end
  def handle_call({:set_nameservers, ifname, nameservers}, _from, state) do
    newnameservers = Dict.put(state.nameservers, ifname, nameservers)
    state = %{state | nameservers: newnameservers}
    write_resolvconf(state)
    {:reply, :ok, state}
  end
  def handle_call({:configure, ifname, options}, _from, state) do
    #TODO
    {:reply, :ok, state}
  end
  def handle_call({:clear, ifname}, _from, state) do
    newdomains = Dict.delete(state.domains, ifname)
    newnameservers = Dict.delete(state.nameservers, ifname)
    state = %{state | nameservers: newnameservers, domains: newdomains}
    write_resolvconf(state)
    {:reply, :ok, state}
  end
  def handle_call(:clear_all, _from, state) do
    state = %Resolvconf{filename: state.filename}
    write_resolvconf(state)
    {:reply, :ok, state}
  end

  defp write_resolvconf(state) do
    domains = for {_ifname, domain} <- state.domains, do: "search #{domain}\n"
    nameservers = for {_ifname, nslist} <- state.nameservers, ns <- nslist, do: "nameserver #{ns}\n"
    File.write!(state.filename, domains ++ nameservers)
  end
end

