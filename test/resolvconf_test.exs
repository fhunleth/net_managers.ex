defmodule ResolvconfTest do
  use ExUnit.Case

  @resolvconf "/tmp/test_resolv.conf"

  setup do
    {:ok, pid} = Resolvconf.start_link @resolvconf
    on_exit(fn() -> File.rm @resolvconf end)
    {:ok, server: pid}
  end

  test "resolveconf path" do
    assert Resolvconf.default_resolvconf_path == "/etc/resolv.conf"
  end

  test "resolvconf created" do
    assert File.exists?(@resolvconf)
  end

  test "set_config domain", %{server: pid} do
    Resolvconf.set_config(pid, "eth0", domain: "troodon-software.com")
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "search troodon-software.com\n"
  end

  test "set_config empty domain", %{server: pid} do
    Resolvconf.set_config(pid, "eth0", domain: "")
    {:ok, contents} = File.read(@resolvconf)
    assert contents == ""
  end

  test "set_config nameserver", %{server: pid} do
    Resolvconf.set_config(pid, "eth0", nameservers: ["192.168.1.1"])
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "nameserver 192.168.1.1\n"
  end

  test "set_config both", %{server: pid} do
    Resolvconf.set_config(pid, "eth0", domain: "troodon-software.com", nameservers: ["192.168.1.1"])
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "search troodon-software.com\nnameserver 192.168.1.1\n"
  end

  test "domain", %{server: pid} do
    Resolvconf.set_domain(pid, "eth0", "troodon-software.com")
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "search troodon-software.com\n"
  end

  test "domains", %{server: pid} do
    Resolvconf.set_domain(pid, "eth0", "troodon-software.com")
    Resolvconf.set_domain(pid, "eth1", "hunleth.com")
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "search troodon-software.com\nsearch hunleth.com\n"
  end

  test "nameserver", %{server: pid} do
    Resolvconf.set_nameservers(pid, "eth0", ["192.168.1.1"])
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "nameserver 192.168.1.1\n"
  end

  test "nameservers", %{server: pid} do
    Resolvconf.set_nameservers(pid, "eth0", ["192.168.1.1", "8.8.8.8"])
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "nameserver 192.168.1.1\nnameserver 8.8.8.8\n"
  end

  test "nameservers2", %{server: pid} do
    Resolvconf.set_nameservers(pid, "eth0", ["192.168.1.1", "8.8.8.8"])
    Resolvconf.set_nameservers(pid, "wlan0", ["192.168.5.1"])
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "nameserver 192.168.1.1\nnameserver 8.8.8.8\nnameserver 192.168.5.1\n"
  end

  test "clear one", %{server: pid} do
    Resolvconf.set_domain(pid, "eth0", "troodon-software.com")
    Resolvconf.set_domain(pid, "eth1", "hunleth.com")
    Resolvconf.set_nameservers(pid, "eth0", ["192.168.1.1", "8.8.8.8"])
    Resolvconf.set_nameservers(pid, "wlan0", ["192.168.5.1"])
    Resolvconf.clear(pid, "eth0")
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "search hunleth.com\nnameserver 192.168.5.1\n"
  end

  test "clear all", %{server: pid} do
    Resolvconf.set_domain(pid, "eth0", "troodon-software.com")
    Resolvconf.set_domain(pid, "eth1", "hunleth.com")
    Resolvconf.set_nameservers(pid, "eth0", ["192.168.1.1", "8.8.8.8"])
    Resolvconf.set_nameservers(pid, "wlan0", ["192.168.5.1"])
    Resolvconf.clear_all(pid)
    {:ok, contents} = File.read(@resolvconf)
    assert contents == ""
  end

end

