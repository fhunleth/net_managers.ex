defmodule PrototestTest do
  use ExUnit.Case

  test "create profiles" do
    profile1 = %NetProfile{
      ifname: "eth0",
      ipv4_address_method: :dhcp
    }

    profile2 = %NetProfile{
      ifname: "eth0",
      ipv4_address_method: :static,
      static_ip: %{
        ipv4_address: "192.168.1.20",
        ipv4_subnet_mask: "255.255.255.0",
        ipv4_gateway: "192.168.1.1"
      },
      static_dns: %{
        domain: "lkc.com",
        dns: ["192.168.25.5", "192.168.1.1"]
      }
    }

    profile3 = %NetProfile{
      ifname: "wlan0",
      wlan: %{
        ssid: "LKC Tech HQ",
        mode: :infrastructure,
        security: :wpa2,
        password: "somepassword",
      },
      ipv4_address_method: :dhcp
    }

    profile4 = %NetProfile{
      ifname: "wlan0",
      wlan: %{
        ssid: "LKC Tech HQ",
        key_mgmt: :WPA_PSK,
        psk: "somepassword",
      },
      ipv4_address_method: :static,
      static_ip: %{
        ipv4_address: "192.168.1.20",
        ipv4_subnet_mask: "255.255.255.0",
        ipv4_gateway: "192.168.1.1"
      },
      static_dns: %{
        domain: "lkc.com",
        dns: ["192.168.25.5", "192.168.1.1"]
      }
    }

    NetCfg.start_link
    NetCfg.set_hostname("myhost")
    NetCfg.set_profiles([profile1, profile3])
  end
end
