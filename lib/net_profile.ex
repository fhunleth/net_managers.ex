defmodule NetProfile do

  defstruct ifname: nil,     # "eth0" or "wlan0", etc.
            type: :ethernet, # :ethernet or :wifi
            ipv4_address_method: :dhcp, # :static, :dhcp, :link_local
            static_ip: %{},  # See NetBasic.set_config
            static_dns: %{}  # {domain: "xyz.com", nameservers: ["8.8.8.8"]}

end
