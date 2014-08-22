defmodule NetManager do
  use GenServer

  defstruct eventmgr: nil,
            netbasic: nil

  def start_link(opts \\ []) do
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

