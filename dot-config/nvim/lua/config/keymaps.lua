-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Snacks explorer
vim.keymap.set("n", "<leader>e", function()
  require("snacks").explorer({ cwd = vim.fn.getcwd() })
end, { desc = "Explorer Snacks (CWD)" })


-- Telescope for finding files
vim.keymap.set("n", "<leader> ", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
