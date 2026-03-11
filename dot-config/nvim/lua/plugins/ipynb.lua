return {
  "shawal/pynb.nvim",
  -- Use the absolute path to your local folder for now
  dir = "/home/shawal/GitHub/pynb.nvim",

  -- Load only when opening a Jupyter Notebook
  ft = "ipynb",

  dependencies = {
    -- Optional: If you want better markdown rendering inside cells
    -- "MeanderingProgrammer/render-markdown.nvim",
  },

  config = function()
    require("pynb").setup({
      keys = {
        next_cell = "j", -- Command mode: Jump to next cell
        prev_cell = "k", -- Command mode: Jump to prev cell
        execute = "<S-Enter>", -- Execute cell and jump next
        edit = "<CR>", -- Enter edit mode
      },
      mouse_support = true, -- Click to select cells
    })
  end,
}
