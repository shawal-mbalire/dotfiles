-- Port: Navigation
-- Contract: Navigation adapter must provide cross-pane navigation keys.
--
-- Domain requirement: "I want tmux-aware navigation with Ctrl-h/j/k/l."
-- Adapter options: vim-tmux-navigator, navigator.lua, etc.

local M = {}

--- Expected adapter shape:
--- @class NavigationPort
---   keys: table   -- key mappings {lhs, rhs, desc}
---   cmd: table    -- command names for lazy-loading

function M.default()
  local nav = require("domain.navigation")
  if not nav.tmux_navigator then
    return nil
  end
  return {
    keys = {
      { nav.keys.tmux_left, "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Tmux Left" },
      { nav.keys.tmux_down, "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Tmux Down" },
      { nav.keys.tmux_up, "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Tmux Up" },
      { nav.keys.tmux_right, "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Tmux Right" },
      { nav.keys.tmux_previous, "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Tmux Previous" },
    },
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
  }
end

return M
