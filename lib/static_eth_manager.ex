defmodule StaticEthManager do
  use GenServer
  require Logger

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

    def init({manager, ifname}) do
      state = %EventHandler{manager: manager, ifname: ifname}
      {:ok, state}
    end

    def handle_event({:net_basic, _, :ifchanged, %{:ifname => ifname}}=event, %EventHandler{ifname: ifname}=state) do
      send state.manager, event
      {:ok, state}
    end
    def handle_event(event, state) do
      Logger.error "Ignoring unmatching event: #{inspect event}"
      {:ok, state}
    end
  end

  def init({netmanager, profile}) do
    resolvconf = NetManager.resolvconf(netmanager)
    net_basic = NetManager.net_basic(netmanager)

    # Register for net_basic events
    GenEvent.add_handler(NetBasic.event_manager(net_basic), EventHandler, {self, profile.ifname})

    state = %StaticEthManager{resolvconf: resolvconf,
                              net_basic: net_basic,
                              profile: profile,
                              ifname: profile.ifname}

    # Check the status and set an initial event through based
    # on whether the interface is up or down
    status = NetBasic.status(net_basic, profile.ifname)
    handle_info({:net_basic, net_basic, :ifchanged, status}, state)

    {:ok, state}
  end

  def handle_info({:net_basic, _, :ifchanged, %{:is_lower_up => true}}, state) do
    Logger.info "#{state.ifname} just came up"
    configure(state)
    {:noreply, state}
  end
  def handle_info({:net_basic, _, :ifchanged, %{:is_lower_up => false}}, state) do
    Logger.info "#{state.ifname} just went down"
    deconfigure(state)
    {:noreply, state}
  end

  defp configure(state) do
    :ok = NetBasic.set_config(state.net_basic, state.ifname, state.profile.static_ip)
    :ok = Resolvconf.set_config(state.resolvconf, state.ifname, state.profile.static_dns)
  end

  defp deconfigure(state) do
    :ok = Resolvconf.clear(state.resolvconf, state.ifname)
  end

end

