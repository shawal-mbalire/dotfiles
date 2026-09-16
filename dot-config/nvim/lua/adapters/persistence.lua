-- Adapter: Session Persistence
-- Implements: ports.session
-- Plugin: folke/persistence.nvim
--
-- This adapter translates the domain session preference
-- into persistence.nvim-specific configuration.

local M = {}

--- Build lazy.nvim spec from domain + port
function M.spec()
  local port = require("ports.session").default()
  if not port then return nil end

  return {
    "folke/persistence.nvim",
    event = port.event,
    opts = port.opts,
  }
end

return M
