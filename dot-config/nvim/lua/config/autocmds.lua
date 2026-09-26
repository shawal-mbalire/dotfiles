-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  end,
})

vim.filetype.add({
  extension = {
    mq5 = "mql5",
    mq4 = "mql4",
    mqh = function(path, bufnr)
      local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
      if first_line:match("^%s*//%s*mql4") then
        return "mql4"
      end
      return "mql5"
    end,
  },
})

vim.treesitter.language.register("cpp", "mql5")
vim.treesitter.language.register("c", "mql4")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "mql5", "mql4" },
  callback = function()
    vim.opt_local.commentstring = "// %s"
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})
