-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.mouse = ""
vim.o.shell = "/usr/bin/env bash"
vim.o.shellcmdflag = "-c"

-- Always use cwd as root, never detect project root
vim.g.root_spec = { "cwd" }

-- clipboard
vim.opt.clipboard = "unnamedplus"

-- trasparent bg (handled in autocmds.lua via ColorScheme autocmd)
