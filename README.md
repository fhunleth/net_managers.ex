# net_managers.ex


## Building

## Scripts

```
{:ok, nm} = NetManager.start_link
profile = %NetProfile{ifname: "eth0", ipv4_address_method: :static, static_ip: %{ipv4_address: "192.168.25.214", ipv4_subnet_mask: "255.255.255.0"}, static_dns: %{domain: "lkc.com", nameservers: ["8.8.8.8"]}}
{:ok, sm} = StaticEthManager.start_link(nm, profile)

```

```
{:ok, nm} = NetManager.start_link
profile = %NetProfile{ifname: "eth0", ipv4_address_method: :dhcp}
{:ok, sm} = DhcpEthManager.start_link(nm, profile)
```

```
System.cmd("/usr/sbin/wpa_supplicant", ["-iwlan0", "-C/var/run/wpa_supplicant", "-B"])
{:ok, nm} = NetManager.start_link
profile = %NetProfile{ifname: "wlan0", ipv4_address_method: :dhcp, wlan: %{ssid: "LKC Tech HQ", key_mgmt: :"WPA-PSK", psk: "testtest"}}
{:ok, sm} = WifiManager.start_link(nm, profile)
```
```
System.cmd("/usr/sbin/wpa_supplicant", ["-iwlan0", "-C/var/run/wpa_supplicant", "-B"])
{:ok, nm} = NetManager.start_link
profile = %NetProfile{ifname: "wlan0", ipv4_address_method: :dhcp, wlan: %{ssid: "LKC Tech HQ-guest", key_mgmt: :NONE}}
{:ok, sm} = WifiManager.start_link(nm, profile)
```

```
System.cmd("/usr/sbin/wpa_supplicant", ["-iwlan0", "-C/var/run/wpa_supplicant", "-B"])
{:ok, nm} = NetManager.start_link
profile = %NetProfile{ifname: "wlan0", ipv4_address_method: :dhcp, wlan: %{ssid: "coderdojodc-5ghz", key_mgmt: :NONE}}
{:ok, sm} = WifiManager.start_link(nm, profile)
```
