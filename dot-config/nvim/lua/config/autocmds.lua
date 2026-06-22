-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local group = vim.api.nvim_create_augroup("user_custom", { clear = true })

-- Auto-save when leaving insert mode, changing text, or leaving buffer
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "BufLeave" }, {
  group = group,
  pattern = "*",
  callback = function(args)
    local buf = args.buf
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
    if buftype == "" and vim.api.nvim_get_option_value("modifiable", { buf = buf }) then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! write")
      end)
    end
  end,
})

-- Auto-reload files changed externally and trigger quick check on focus
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = group,
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("silent! checktime")
    end
  end,
})

-- Notify when a file is reloaded from disk
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  pattern = "*",
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
  end,
})
