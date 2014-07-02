defmodule DnsResolverTest do
  use ExUnit.Case

  @resolvconf "/tmp/test_resolv.conf"

  setup do
    {:ok, pid} = DnsResolver.start_link @resolvconf
    on_exit(fn() -> File.rm @resolvconf end)
    {:ok, server: pid}
  end

  test "resolveconf path" do
    assert DnsResolver.default_resolvconf_path == "/etc/resolv.conf"
  end

  test "resolvconf created" do
    assert File.exists?(@resolvconf)
  end

  test "domain", %{server: pid} do
    DnsResolver.set_domain(pid, "eth0", "troodon-software.com")
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "search troodon-software.com\n"
  end

  test "domains", %{server: pid} do
    DnsResolver.set_domain(pid, "eth0", "troodon-software.com")
    DnsResolver.set_domain(pid, "eth1", "hunleth.com")
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "search troodon-software.com\nsearch hunleth.com\n"
  end

  test "nameserver", %{server: pid} do
    DnsResolver.set_nameservers(pid, "eth0", ["192.168.1.1"])
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "nameserver 192.168.1.1\n"
  end

  test "nameservers", %{server: pid} do
    DnsResolver.set_nameservers(pid, "eth0", ["192.168.1.1", "8.8.8.8"])
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "nameserver 192.168.1.1\nnameserver 8.8.8.8\n"
  end

  test "nameservers2", %{server: pid} do
    DnsResolver.set_nameservers(pid, "eth0", ["192.168.1.1", "8.8.8.8"])
    DnsResolver.set_nameservers(pid, "wlan0", ["192.168.5.1"])
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "nameserver 192.168.1.1\nnameserver 8.8.8.8\nnameserver 192.168.5.1\n"
  end

  test "clear one", %{server: pid} do
    DnsResolver.set_domain(pid, "eth0", "troodon-software.com")
    DnsResolver.set_domain(pid, "eth1", "hunleth.com")
    DnsResolver.set_nameservers(pid, "eth0", ["192.168.1.1", "8.8.8.8"])
    DnsResolver.set_nameservers(pid, "wlan0", ["192.168.5.1"])
    DnsResolver.clear(pid, "eth0")
    {:ok, contents} = File.read(@resolvconf)
    assert contents == "search hunleth.com\nnameserver 192.168.5.1\n"
  end

  test "clear all", %{server: pid} do
    DnsResolver.set_domain(pid, "eth0", "troodon-software.com")
    DnsResolver.set_domain(pid, "eth1", "hunleth.com")
    DnsResolver.set_nameservers(pid, "eth0", ["192.168.1.1", "8.8.8.8"])
    DnsResolver.set_nameservers(pid, "wlan0", ["192.168.5.1"])
    DnsResolver.clear_all(pid)
    {:ok, contents} = File.read(@resolvconf)
    assert contents == ""
  end

end

