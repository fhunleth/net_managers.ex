defmodule NetCfg.Settings.IPv4 do
  defstruct mode: :dynamic,
            address: nil,
            broadcast: nil,
            subnet: nil,
            default_route: nil,
            domain: nil,
            dns: []

end
