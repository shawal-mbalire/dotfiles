-- Domain: Editor behavior preferences
-- Pure configuration — no plugin imports, no side effects.
-- This module defines WHAT the editor should do, not HOW (adapters implement HOW).

local M = {}

--- Transparency preference — applied across all UI elements
M.transparency = true

--- Auto-reload files changed externally (e.g. tmux editing)
M.auto_reload = true

--- Session persistence settings
M.session = {
  enabled = true,
  auto_load = true, -- load session on BufReadPre
}

--- Filetypes the user works with (used by adapters for lazy-loading)
M.filetypes = {
  "python",
  "markdown",
  "ipynb",
  "mql",
  "go",
  "rust",
  "typescript",
  "lua",
  "terraform",
}

return M
