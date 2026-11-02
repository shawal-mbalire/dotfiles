-- tersh.nvim: images, video, notebooks, markdown with LaTeX and Plotly as
-- cards in the tersh terminal. To hack on a local checkout instead, replace
-- the repo with `dir = "~/GitHub/tersh", name = "tersh"`.
return {
  {
    dir = "~/GitHub/tersh", -- local checkout; use "shawal-mbalire/tersh" for the release
    name = "tersh",
    main = "tersh",
    lazy = false, -- small, and needed at startup to render files as they open
    opts = {
      preview = { split = "vertical", size = 0.5 },
    },
    keys = {
      { "<leader>Tp", "<cmd>TershPreview<cr>", desc = "tersh: toggle preview" },
      { "<leader>Ts", "<cmd>TershShow<cr>", desc = "tersh: show file under cursor" },
      { "<leader>Tx", "<cmd>TershClose!<cr>", desc = "tersh: close all cards" },
    },
  },
}
