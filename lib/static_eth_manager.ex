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
      Logger.info "Got matching event: #{inspect event}"
      send state.manager, event
      {:ok, state}
    end
    def handle_event(event, state) do
      Logger.error "Got unmatching event: #{inspect event}"
      send state.manager, event
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

    # Clean up any old configuration on the interface
    deconfigure(state)

    status = NetBasic.status(net_basic, profile.ifname)

    # TODO: if status is up, then send ifup notification
    Logger.info "Initial #{state.ifname} status is: #{inspect status}"
    handle_info({:net_basic, net_basic, :ifchanged, status}, state)

    {:ok, state}
  end

  def handle_info({:net_basic, _, :ifchanged, %{:is_lower_up => true}}, state) do
    Logger.info "#{state.ifname} just came up"
    configure(state)
  end
  def handle_info({:net_basic, _, :ifchanged, %{:is_lower_up => false}}, state) do
    Logger.info "#{state.ifname} just went down"
    deconfigure(state)
  end

  defp configure(state) do
    :ok = NetBasic.set_config(state.net_basic, state.profile.static_ip)
    :ok = Resolvconf.configure(state.resolvconf, state.profile.static_dns)
  end

  defp deconfigure(state) do
    :ok = Resolvconf.clear(state.resolvconf, state.profile.ifname)
  end

end

