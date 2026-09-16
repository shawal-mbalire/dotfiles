-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--
-- Infrastructure layer: Neovim-specific configuration.
-- Domain preferences are in lua/domain/.

vim.opt.autoread = true
vim.opt.updatetime = 200
vim.opt.termguicolors = true

-- Workaround for Neovim 0.12.5 bug: vim.fs.abspath asserts uv.cwd() ~= nil
-- but uv.cwd() can return nil during BufNewFile autocommands
local uv = vim.uv or vim.loop
local orig_abspath = vim.fs.abspath
vim.fs.abspath = function(path, opts)
  local ok, result = pcall(orig_abspath, path, opts)
  if ok then
    return result
  end
  if type(path) == "string" then
    return path
  end
  error(result)
end
