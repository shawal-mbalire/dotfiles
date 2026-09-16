-- Domain: Navigation behavior
-- Pure configuration — defines WHAT navigation should feel like.

local M = {}

--- Tmux integration preference
M.tmux_navigator = true

--- Keybindings for navigation (adapters wire these to actual plugins)
M.keys = {
  tmux_left = "<C-h>",
  tmux_down = "<C-j>",
  tmux_up = "<C-k>",
  tmux_right = "<C-l>",
  tmux_previous = "<C-\\>",
}

return M
