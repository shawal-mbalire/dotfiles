-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Neo-tree for file explorer
vim.keymap.set("n", "<leader>e", "<cmd>NeotreeToggle<cr>", { desc = "Toggle Neo-tree" })

-- Telescope for finding files
vim.keymap.set("n", "<leader> ", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
