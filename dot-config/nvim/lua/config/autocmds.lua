-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Infrastructure layer: Neovim event handlers.
-- Domain preferences are in lua/domain/editor.lua.

local editor = require("domain.editor")

-- Auto-reload files when changed externally (e.g. tmux editing)
if editor.auto_reload then
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    callback = function()
      vim.defer_fn(function()
        vim.cmd("checktime")
      end, 50)
    end,
  })
end
