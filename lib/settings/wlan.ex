defmodule NetCfg.Settings.Wlan do
  defstruct ssid: nil,
            mode: :infrastructure,
            security: :none,
            password: nil
end

