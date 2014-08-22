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

    defstruct manager: nil,
              ifname: nil

    def init(manager, ifname) do
      {:ok, %EventHandler{manager: manager, ifname: ifname}}
    end

    def handle_event({:net_basic, _, :ifchanged, %{:ifname => ifname}}=event, %EventHandler{ifname: ifname}=state) do
      send state.manager, event
      {:ok, state}
    end
    def handle_event(event, state) do
      send state.manager, event
      {:ok, state}
    end
  end

  def init({netmanager, profile}) do
    resolvconf = NetManager.resolvconf(netmanager)
    net_basic = NetManager.net_basic(netmanager)

    # Register for net_basic events
    GenEvent.add_handler(net_basic.event_manager(), EventHandler, {self, profile.ifname})

    state = %StaticEthManager{resolvconf: resolvconf,
                              net_basic: net_basic,
                              profile: profile,
                              ifname: to_erlstring(profile.ifname)}

    # Clean up any old configuration on the interface
    deconfigure(state)

    status = NetBasic.status(net_basic, profile.ifname)

    # TODO: if status is up, then send ifup notification

    {:ok, state}
  end

  def handle_info({:net_basic, _, :ifchanged, %{}}, state) do
defmodule NetManager do
  use GenServer

  defstruct eventmgr: nil,
            netbasic: nil

  def start_link(opts // []) do
    GenServer.start_link(__MODULE__, :noargs, opts)
  end

  def event_manager(pid) do
    GenServer.call(pid, :event_manager)
  end
  def net_basic(pid) do
    GenServer.call(pid, :net_basic)
  end

  def init(_args) do
    {:ok, eventmgr} = GenEvent.start_link
    {:ok, netbasic} = NetBasic.start_link
    state = %NetManager{eventmgr: eventmgr, netbasic: netbasic}
    {:ok, state}
  end

  def handle_call(:event_manager, _from, state) do
    {:reply, state.eventmgr, state}
  end
  def handle_call(:net_basic, _from, state) do
    {:reply, state.eventmgr, state}
  end

end

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

