defmodule StaticEthManager do
  use GenServer

  defstruct resolvconf: nil,
            net_basic: nil,
            profile: nil,
            ifname: nil

  def start_link(netmanager, profile, opts \\ []) do
    GenServer.start_link(__MODULE__, {netmanager, profile}, opts)
  end



  defmodule EventHandler do
    use GenEvent
    def handle_event({:net_basic, _, :ifchanged, %{ifname <= state.ifname}, manager) do
      send manager, event
      {:ok, manager}
    end
    def handle_event(event, manager) do
      send manager, event
      {:ok, manager}
    end
  end

  def init({netmanager, profile}) do
    resolvconf = NetManager.resolvconf(netmanager)
    net_basic = NetManager.net_basic(netmanager)

    state = %StaticEthManager{resolvconf: resolvconf,
                              net_basic: net_basic,
                              profile: profile,
                              ifname: to_erlstring(profile.ifname)}

    # Clean up any old configuration on the interface
    deconfigure(state)

    status = NetBasic.status(net_basic, profile.ifname)

    {:ok, state}
  end

  def handle_info({:net_basic, _, :ifchanged, %{}, state) do
  end

  defp configure(state) do
    :ok = Resolvconf.set_config(state.net_basic, state.profile.static_ip)
    :ok = Resolvconf.configure(state.resolvconf, state.profile.static_dns)
  end

  defp deconfigure(state) do
    :ok = Resolvconf.clear(state.resolvconf, state.profile.ifname)
  end

  defp to_erlstring(str) when is_list(str), do: str
  defp to_erlstring(str) when is_binary(str), do: String.to_char_list(str)
end

