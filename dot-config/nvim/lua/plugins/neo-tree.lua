return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    sources = { "filesystem", "buffers", "git_status", "diagnostics" },
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_hidden = false,
        hide_git_ignored = false,
      },
      follow_current_file = {
        enabled = true, -- when true, neo-tree will open and highlight the file in the current buffer
      },
      group_empty_dirs = {
        enable = true, -- when true, empty folders will be grouped together
      },
    },
  },
}
