-- Port: Colorscheme
-- Contract: Any colorscheme adapter must provide setup(opts) and apply.
--
-- Domain requirement: "I want a specific colorscheme with transparency."
-- Adapter options: catppuccin, tokyonight, gruvbox, etc.

local M = {}

--- Expected adapter shape (duck-typed interface):
--- @class ColorschemePort
---   name: string          -- plugin name (e.g. "catppuccin/nvim")
---   opts: table           -- plugin-specific options
---   config: function|nil  -- optional custom config function

--- Default colorscheme config from domain
function M.default()
  local ui = require("domain.ui")
  return {
    name = "catppuccin/nvim",
    opts = {
      transparent_background = ui.transparency.enabled,
      integrations = {
        cmp = true,
        gitsigns = true,
        treesitter = true,
        notify = true,
        mini = true,
        snacks = true,
        which_key = true,
      },
    },
  }
end

return M
