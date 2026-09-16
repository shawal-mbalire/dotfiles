-- Adapter: Python Venv Selector
-- Implements: ports.venv
-- Plugin: linux-cultist/venv-selector.nvim
--
-- This adapter translates the domain Python preference
-- into venv-selector.nvim-specific configuration.

local M = {}

--- Build lazy.nvim spec from domain + port
function M.spec()
  local port = require("ports.venv").default()
  if not port then return nil end

  return {
    port.name,
    dependencies = port.dependencies,
    ft = port.ft,
    keys = port.keys,
    opts = port.opts,
  }
end

return M
