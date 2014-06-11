defmodule PrototestTest do
  use ExUnit.Case

  test "create profiles" do
    profile1 = %NetCfg.Profile{
      interface: "eth0",
      ipv4: %NetCfg.Settings.IPv4{
        mode: :dynamic
      }
    }

    profile2 = %NetCfg.Profile{
      interface: "eth0",
      ipv4: %NetCfg.Settings.IPv4{
        mode: :static,
        address: "192.168.1.20",
        subnet: "255.255.255.0",
        default_route: "192.168.1.1",
        domain: "lkc.com",
        dns: ["192.168.25.5", "192.168.1.1"]
      }
    }

    profile3 = %NetCfg.Profile{
      interface: "wlan0",
      wlan: %NetCfg.Settings.Wlan{
        ssid: "LKC Tech HQ",
        mode: :infrastructure,
        security: :wpa2,
        password: "somepassword",
      },
      ipv4: %NetCfg.Settings.IPv4{
        mode: :dynamic
      }
    }

    profile4 = %NetCfg.Profile{
      interface: "wlan0",
      wlan: %NetCfg.Settings.Wlan{
        ssid: "LKC Tech HQ",
        mode: :infrastructure,
        security: :wpa2,
        password: "somepassword",
      },
      ipv4: %NetCfg.Settings.IPv4{
        mode: :static,
        address: "192.168.1.20",
        subnet: "255.255.255.0",
        default_route: "192.168.1.1",
        dns: ["192.168.25.5", "192.168.1.1"]
      }
    }

    NetCfg.start_link
    NetCfg.set_hostname("myhost")
    NetCfg.set_profiles([profile1, profile3])
  end
end
