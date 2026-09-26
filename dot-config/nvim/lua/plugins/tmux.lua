return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left (tmux/nvim)" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down (tmux/nvim)" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up (tmux/nvim)" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right (tmux/nvim)" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate Previous (tmux/nvim)" },
  },
}
