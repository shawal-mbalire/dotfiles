return {
  "linux-cultist/venv-selector.nvim",
  opts = {
    options = {
      -- Automatically re-activate the last selected venv when reopening a project
      cached_venv_automatic_activation = true,
      notify_user_on_venv_activation = true,
    },
    search = {
      -- Ensure common local venv directories are picked up
      venv = {
        command = "fd",
        args = {
          "--absolute-path",
          "--type",
          "d",
          "--max-depth",
          "2",
          "bin/python$",
        },
        pattern = "(.*)/bin/python$",
        on_select = function(result)
          return vim.fs.dirname(result)
        end,
      },
    },
  },
  ft = "python",
  keys = {
    { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" },
  },
}
