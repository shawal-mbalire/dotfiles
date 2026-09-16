-- Adapter: Catppuccin Colorscheme
-- Implements: ports.colorscheme
-- Plugin: catppuccin/nvim
--
-- This adapter translates the domain colorscheme preference
-- into catppuccin-specific configuration.

local M = {}

--- Build lazy.nvim spec from domain + port
function M.spec()
  local port = require("ports.colorscheme").default()
  if not port then return nil end

  local ui = require("domain.ui")

  return {
    port.name,
    opts = port.opts,
    config = function(_, opts)
      require("catppuccin").setup(opts)

      local function apply_transparency()
        local hl = vim.api.nvim_set_hl
        for _, group in ipairs(ui.transparency.highlights) do
          hl(0, group, { bg = "NONE", ctermbg = "NONE" })
        end
        -- Force Normal highlight transparent via vim.cmd (bypasses any caching)
        vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
        vim.cmd("highlight NormalNC guibg=NONE ctermbg=NONE")
        vim.cmd("highlight NormalFloat guibg=NONE ctermbg=NONE")
      end

      apply_transparency()

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = apply_transparency,
      })

      -- Final pass after ALL plugins load — catches late overrides
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          vim.defer_fn(apply_transparency, 100)
        end,
      })
    end,
  }
end

return M
