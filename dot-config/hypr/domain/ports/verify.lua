-- Verify an adapter satisfies a domain port contract.
-- Fail loud: the first missing method aborts with a precise message.

local M = {}

M.monitor = require("domain.ports.monitor")
M.environment = require("domain.ports.environment")
M.input = require("domain.ports.input")
M.binding = require("domain.ports.binding")
M.command = require("domain.ports.command")
M.visual = require("domain.ports.visual")
M.layer = require("domain.ports.layer")
M.window_rule = require("domain.ports.window_rule")
M.runtime = require("domain.ports.runtime")
M.wallpaper = require("domain.ports.wallpaper")
M.logger = require("domain.ports.logger")
M.time = require("domain.ports.time")
M.lifetime = require("domain.ports.lifetime")

-- Ports implemented by the single Hyprland adapter (one external system).
M.HYPR_PORTS = {
  M.monitor,
  M.environment,
  M.input,
  M.binding,
  M.command,
  M.visual,
  M.layer,
  M.window_rule,
  M.runtime,
}

function M.assert_port(adapter, port)
  for name, value in pairs(port) do
    if type(value) == "function" then
      assert(
        type(adapter[name]) == "function",
        string.format("Adapter does not implement %s:%s", port.NAME, name)
      )
    end
  end
end

function M.assert_ports(adapter, ports)
  for _, port in ipairs(ports) do
    M.assert_port(adapter, port)
  end
end

return M
