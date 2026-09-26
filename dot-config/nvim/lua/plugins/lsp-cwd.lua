return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers["*"] = vim.tbl_deep_extend("force", opts.servers["*"] or {}, {
        root_dir = function()
          return vim.fn.getcwd()
        end,
      })
    end,
  },
}
