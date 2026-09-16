-- Port: Rendering
-- Contract: Render adapter must provide setup() for markdown, ipynb, images.
--
-- Domain requirement: "I want to render markdown, notebooks, and images in Neovim."
-- Adapter options: neovim-renderer-plugins, render-markdown.nvim, etc.

local M = {}

--- Expected adapter shape:
--- @class RenderPort
---   name: string       -- plugin name
---   ft: table          -- filetypes to trigger loading
---   config: function   -- setup function

function M.default()
  local ui = require("domain.ui")
  if not ui.render.markdown and not ui.render.ipynb and not ui.render.images then
    return nil
  end
  return {
    name = "shawal-mbalire/neovim-renderer-plugins",
    ft = ui.render.filetypes,
    config = function()
      require("renderer-markdown").setup()
      require("renderer-ipynb").setup()
      require("renderer-image").setup()
    end,
  }
end

return M
