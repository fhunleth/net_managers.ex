defmodule NetManager do
  use GenServer

  defstruct eventmgr: nil,
            netbasic: nil,
            resolvconf: nil

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :noargs, opts)
  end

  def event_manager(pid) do
    GenServer.call(pid, :event_manager)
  end
  def net_basic(pid) do
    GenServer.call(pid, :net_basic)
  end
  def resolvconf(pid) do
    GenServer.call(pid, :resolvconf)
  end

  def init(_args) do
    {:ok, eventmgr} = GenEvent.start_link
    {:ok, netbasic} = NetBasic.start_link(eventmgr)
    {:ok, resolvconf} = Resolvconf.start_link("/tmp/resolv.conf")
    state = %NetManager{eventmgr: eventmgr, netbasic: netbasic, resolvconf: resolvconf}
    {:ok, state}
  end

  def handle_call(:event_manager, _from, state) do
    {:reply, state.eventmgr, state}
  end
  def handle_call(:net_basic, _from, state) do
    {:reply, state.netbasic, state}
  end
  def handle_call(:resolvconf, _from, state) do
    {:reply, state.resolvconf, state}
  end

end

