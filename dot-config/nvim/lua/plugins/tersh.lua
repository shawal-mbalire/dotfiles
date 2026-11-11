-- tersh.nvim: images, video, notebooks, markdown with LaTeX and Plotly as
-- cards in the tersh terminal.
--
-- Installed from GitHub like any other plugin (pinned in lazy-lock.json, latest
-- release tag). `dev = true` uses the checkout in ~/GitHub/tersh while it
-- exists (see `dev` in config/lazy.lua) and falls back to the GitHub copy when
-- it doesn't, so deleting or moving the checkout never breaks Neovim.
-- The repository's lazy.lua already sets main = "tersh", lazy = false.
return {
  {
    "shawal-mbalire/tersh",
    version = "*",
    dev = true,
    lazy = false, -- load at startup so files render as they open (keys would make it lazy)
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
