defmodule DhcpEthManager do
  use GenServer
  require Logger

  # The current state machine state is called "context" to avoid confusion between server
  # state and state machine state.
  defstruct context: :down,
            ifname: nil,
            resolvconf: nil,
            net_basic: nil,
            profile: nil,
            dhcp_pid: nil

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

    # Filter out ifup and ifdown events
    def handle_event({:net_basic, _, :ifchanged, %{:ifname => ifname, :is_lower_up => true}}, %EventHandler{ifname: ifname}=state) do
      send state.manager, :ifup
      {:ok, state}
    end
    def handle_event({:net_basic, _, :ifchanged, %{:ifname => ifname, :is_lower_up => false}}, %EventHandler{ifname: ifname}=state) do
      send state.manager, :ifdown
      {:ok, state}
    end

    # DHCP events
    # :bound, :renew, :deconfig, :nak
    def handle_event({:udhcpc, _, event, %{:ifname => ifname}=info}, %EventHandler{ifname: ifname}=state) do
      send state.manager, {event, info}
      {:ok, state}
    end

    def handle_event(event, state) do
      Logger.error "DhcpEthManager: ignoring unmatching event: #{inspect event}"
      {:ok, state}
    end
  end

  def init({netmanager, profile}) do
    resolvconf = NetManager.resolvconf(netmanager)
    net_basic = NetManager.net_basic(netmanager)
    event_manager = NetBasic.event_manager(net_basic)

    # Register for net_basic events
    GenEvent.add_handler(event_manager, EventHandler, {self, profile.ifname})

    state = %DhcpEthManager{resolvconf: resolvconf,
                            net_basic: net_basic,
                            profile: profile,
                            ifname: profile.ifname}

    # Check the status and send an initial event through based
    # on whether the interface is up or down
    # NOTE: GenEvent.notify/2 is asynchronous which is good and bad. It's
    #       good since if it were synchronous, we'd certainly mess up our state.
    #       It's bad since there's a race condition between when we get the status
    #       and when the update is sent. I can't image us hitting the race condition
    #       though. :)
    status = NetBasic.status(net_basic, profile.ifname)
    GenEvent.notify(event_manager, {:net_basic, net_basic, :ifchanged, status})

    {:ok, state}
  end

  def handle_info(event, state) do
    Logger.info "DhcpEthManager(#{state.ifname}, #{state.context}) got event #{inspect event}"
    state = consume(state.context, event, state)
    {:noreply, state}
  end

  ## State machine implementation
  defp goto_context(state, newcontext) do
    %DhcpEthManager{state | context: newcontext}
  end

  ## Context: :down
  defp consume(:down, :ifup, state) do
    state
      |> start_udhcpc
      |> goto_context(:dhcp)
  end
  defp consume(:down, :ifdown, state) do
    # Udhcpc should be stopped, but kill it for good measure just in case
    state |> stop_udhcpc
  end

  ## Context: :dhcp
  defp consume(:dhcp, {:deconfig, _info}, state), do: state
  defp consume(:dhcp, {:bound, info}, state) do
    state
      |> configure(info)
      |> goto_context(:up)
  end
  defp consume(:dhcp, :ifdown, state) do
    state
      |> stop_udhcpc
      |> goto_context(:down)
  end

  ## Context: :up
  defp consume(:up, :ifdown, state) do
    state
      |> stop_udhcpc
      |> deconfigure
      |> goto_context(:down)
  end

  ## Context: :wait_for_retry
  defp consume(:wait_for_retry, :ifdown, state) do
    state
      |> stop_udhcpc
      |> goto_context(:down)
  end

  defp stop_udhcpc(state) do
    if is_pid(state.dhcp_pid) do
      Udhcpc.stop(state.dhcp_pid)
      %DhcpEthManager{state | dhcp_pid: nil}
    else
      state
    end
  end
  defp start_udhcpc(state) do
    state = stop_udhcpc(state)
    udhcpc = Udhcpc.start_link(state.ifname, NetBasic.event_manager(state.net_basic))
    %DhcpEthManager{state | dhcp_pid: udhcpc}
  end

  defp configure(state, info) do
    :ok = NetBasic.set_config(state.net_basic, state.ifname, info)
    :ok = Resolvconf.set_config(state.resolvconf, state.ifname, info)
    state
  end

  defp deconfigure(state) do
    :ok = Resolvconf.clear(state.resolvconf, state.ifname)
    state
  end

end

