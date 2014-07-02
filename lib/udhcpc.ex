defmodule Udhcpc do
  use GenServer

  defstruct ifname: nil,
            port: nil

  def start_link(ifname) do
    GenServer.start_link(__MODULE__, ifname)
  end

  def release(pid) do
    GenServer.call(pid, :release)
  end

  def renew(pid) do
    GenServer.call(pid, :renew)
  end


  def init(ifname) do
    path = System.find_executable("udhcpc") || raise "udhcpc not found"
    script = :code.priv_dir(:prototest) ++ '/udhcpc.sh'
    args = ['--interface', String.to_char_list(ifname), '--script', script, '--foreground']
      sudo_path = System.find_executable("sudo")
      args = [path] ++ args
      path = sudo_path
    IO.inspect path
    IO.inspect args
    port = Port.open({:spawn_executable, path},
                     [{:args, args}, :exit_status, :stderr_to_stdout, {:line, 256}])
    { :ok, %Udhcpc{ifname: ifname, port: port} }
  end

  def handle_call(:renew, _from, state) do
    signal_udhcpc(state.port, "USR1")
    {:reply, :ok, state}
  end

  def handle_call(:release, _from, state) do
    signal_udhcpc(state.port, "USR2")
    {:reply, :ok, state}
  end

  def handle_info({_, {:data, {:eol, message}}}, state) do
    message
      |> List.to_string
      |> String.split(",")
      |> handle_udhcpc(state)
  end

  defp handle_udhcpc(["deconfig", interface | _rest], state) do
    IO.puts "Deconfigure #{interface}"
    {:noreply, state}
  end
  defp handle_udhcpc(["bound", interface, ip, broadcast, subnet, router, domain, dns, _message], state) do
    IO.puts "Bound #{interface}: IP=#{ip}, dns=#{inspect dns}"
    {:noreply, state}
  end
  defp handle_udhcpc(["renew", interface, ip, broadcast, subnet, router, domain, dns, _message], state) do
    IO.puts "Renew #{interface}"
    {:noreply, state}
  end
  defp handle_udhcpc(["leasefail", interface, _ip, _broadcast, _subnet, _router, _domain, _dns, message], state) do
    IO.puts "#{interface}: leasefail #{message}"
    {:noreply, state}
  end
  defp handle_udhcpc(["nak", interface, _ip, _broadcast, _subnet, _router, _domain, _dns, message], state) do
    IO.puts "#{interface}: NAK #{message}"
    {:noreply, state}
  end
  defp handle_udhcpc(something_else, state) do
    msg = List.foldl(something_else, "", &<>/2)
    IO.puts "Got info message: #{msg}"
    {:noreply, state}
  end

  defp signal_udhcpc(port, signal) do
    {:os_pid, os_pid} = Port.info(port, :os_pid)
    System.cmd("sudo kill -#{signal} #{os_pid}")
  end
end

