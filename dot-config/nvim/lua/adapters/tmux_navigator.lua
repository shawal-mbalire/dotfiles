-- Adapter: Tmux Navigator
-- Implements: ports.navigation
-- Plugin: christoomey/vim-tmux-navigator
--
-- This adapter translates the domain navigation preference
-- into vim-tmux-navigator-specific configuration.

local M = {}

--- Build lazy.nvim spec from domain + port
function M.spec()
  local port = require("ports.navigation").default()
  if not port then return nil end

  return {
    "christoomey/vim-tmux-navigator",
    cmd = port.cmd,
    keys = port.keys,
  }
end

return M
