return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      doc = {
        inline = true,
        float = true,
      },
    },
    explorer = { enabled = true },
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
}
