defmodule NetCfg do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def set_hostname(name) do
    GenServer.call(__MODULE__, {:set_hostname, name})
  end

  def set_profiles(profiles) do
    GenServer.call(__MODULE__, {:set_profiles, profiles})
  end

  # Server
  def init(_args) do
    {:ok, []}
  end

  def handle_call({:set_hostname, name}, _from, state) do
    {:reply, :ok, state}
  end
  def handle_call({:set_profiles, profiles}, _from, state) do
    {:reply, :ok, state}
  end
end
