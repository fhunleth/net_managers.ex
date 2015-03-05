# Copyright 2014 LKC Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Udhcpc do
  use GenServer

  defstruct ifname: nil,
            manager: nil,
            port: nil

  @doc """
  Start and link a Udhcpc process for the specified interface (i.e., eth0,
  wlan0). This function spawns a GenEvent for getting responses and
  notifications from the DHCP server. Call event_manager/1 to get the
  GenEvent pid.
  """
  def start_link(ifname) do
    { :ok, manager } = GenEvent.start_link
    start_link(ifname, manager)
  end

  @doc """
  Start and link a Udhcpc process for the specified interface (i.e., eth0,
  wlan0). Pass a GenEvent in to receive messages back from the DHCP server.
  """
  def start_link(ifname, event_manager) do
    GenServer.start_link(__MODULE__, {ifname, event_manager})
  end

  @doc """
  Get a reference to the GenEvent event manager in use by this Udhcpc
  """
  def event_manager(pid) do
    GenServer.call(pid, :event_manager)
  end

  @doc """
  Notify the DHCP server to release the IP address currently assigned to
  this interface. After calling this, be sure to disassociate the IP address
  from the interface so that packets don't accidentally get sent or processed.
  """
  def release(pid) do
    GenServer.call(pid, :release)
  end

  @doc """
  Renew the lease on the IP address with the DHCP server.
  """
  def renew(pid) do
    GenServer.call(pid, :renew)
  end

  @doc """
  Stop the dhcp client
  """
  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def init({ifname, event_manager}) do
    priv_path = :code.priv_dir(:net_managers)
    args = ["--interface", ifname,
            "--script", "#{priv_path}/udhcpc.sh",
            "--foreground"]
          |> add_hostname_arg(hostname)
    port = Port.open({:spawn_executable, "#{priv_path}/udhcpc_wrapper"},
                     [{:args, args}, :exit_status, :stderr_to_stdout, {:line, 256}])
    { :ok, %Udhcpc{ifname: ifname, manager: event_manager, port: port} }
  end

  defp add_hostname_arg(args, "noname"), do: args
  defp add_hostname_arg(args, name), do: args ++ ["-x", "hostname:#{name}"]

  def terminate(_reason, state) do
    # Closing Erlang ports just turns off I/O. That's not good enough for
    # udhcpc. It needs to be killed.
    Port.close(state.port)
    :ok
  end

  def handle_call(:event_manager, _from, state) do
    {:reply, state.manager, state}
  end

  def handle_call(:renew, _from, state) do
    # If we send a byte with the value 1 to the wrapper, it will turn it into
    # a SIGUSR1 for udhcpc so that it renews the IP address.
    Port.command(state.port, <<1>>);
    {:reply, :ok, state}
  end

  def handle_call(:release, _from, state) do
    Port.command(state.port, <<2>>);
    {:reply, :ok, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_info({_, {:data, {:eol, message}}}, state) do
    message
      |> List.to_string
      |> String.split(",")
      |> handle_udhcpc(state)
  end

  defp handle_udhcpc(["deconfig", ifname | _rest], state) do
    IO.puts "Deconfigure #{ifname}"
    GenEvent.notify(state.manager, {:udhcpc, self, :deconfig, %{ifname: ifname}})
    {:noreply, state}
  end
  defp handle_udhcpc(["bound", ifname, ip, broadcast, subnet, router, domain, dns, _message], state) do
    dnslist = String.split(dns, " ")
    IO.puts "Bound #{ifname}: IP=#{ip}, dns=#{inspect dns}"
    GenEvent.notify(state.manager, {:udhcpc, self, :bound, %{ifname: ifname, ipv4_address: ip, ipv4_broadcast: broadcast, ipv4_subnet_mask: subnet, ipv4_gateway: router, domain: domain, nameservers: dnslist}})
    {:noreply, state}
  end
  defp handle_udhcpc(["renew", ifname, ip, broadcast, subnet, router, domain, dns, _message], state) do
    dnslist = String.split(dns, " ")
    IO.puts "Renew #{ifname}"
    GenEvent.notify(state.manager, {:udhcpc, self, :renew, %{ifname: ifname, ipv4_address: ip, ipv4_broadcast: broadcast, ipv4_subnet_mask: subnet, ipv4_gateway: router, domain: domain, nameservers: dnslist}})
    {:noreply, state}
  end
  defp handle_udhcpc(["leasefail", ifname, _ip, _broadcast, _subnet, _router, _domain, _dns, message], state) do
    IO.puts "#{ifname}: leasefail #{message}"
    GenEvent.notify(state.manager, {:udhcpc, self, :leasefail, %{ifname: ifname, message: message}})
    {:noreply, state}
  end
  defp handle_udhcpc(["nak", ifname, _ip, _broadcast, _subnet, _router, _domain, _dns, message], state) do
    IO.puts "#{ifname}: NAK #{message}"
    GenEvent.notify(state.manager, {:udhcpc, self, :nak, %{ifname: ifname, message: message}})
    {:noreply, state}
  end
  defp handle_udhcpc(something_else, state) do
    msg = List.foldl(something_else, "", &<>/2)
    IO.puts "Got info message: #{msg}"
    {:noreply, state}
  end

  defp hostname() do
    # Turn :sname@host into a hostname
    # Returns "nohost" if Erlang distribution not enabled
    node
      |> to_string
      |> String.split("@")
      |> Enum.at(1)
  end
end

