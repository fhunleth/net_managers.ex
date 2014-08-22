defmodule StaticEthSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end


  def init({net_manager, profile}) do
    children = [
      worker(StaticEthManager, [{net_manager, profile}, [name: child_name(StaticEthManager, profile.ifname)]])
      ]

    supervise(children, strategy: :one_for_one)
  end

  defp child_name(who, ifname) do
    Module.concat([__MODULE__, who, ifname])
  end
end
