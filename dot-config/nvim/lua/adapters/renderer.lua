-- Adapter: Neovim Renderer Plugins
-- Implements: ports.render
-- Plugin: shawal-mbalire/neovim-renderer-plugins
--
-- This adapter translates the domain render preference
-- into renderer plugin-specific configuration.

local M = {}

--- Build lazy.nvim spec from domain + port
function M.spec()
  local port = require("ports.render").default()
  if not port then return nil end

  return {
    port.name,
    ft = port.ft,
    config = port.config,
  }
end

return M
