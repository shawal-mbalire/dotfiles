return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true, -- Shows hidden files by default
            -- ignored = true, -- Uncomment to also show files ignored by .gitignore
          },
        },
      },
    },
  },
}
