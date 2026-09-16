-- Port: Python Virtual Environment Selector
-- Contract: Venv adapter must provide a picker for Python venvs.
--
-- Domain requirement: "I want to select Python virtual environments easily."
-- Adapter options: venv-selector.nvim, etc.

local M = {}

--- Expected adapter shape:
--- @class VenvPort
---   name: string
---   ft: string
---   keys: table
---   dependencies: table

function M.default()
  local python = require("domain.languages").python
  if not python.venv_selector then
    return nil
  end
  return {
    name = "linux-cultist/venv-selector.nvim",
    ft = "python",
    keys = { { python.venv_key, "<cmd>VenvSelect<cr>" } },
    dependencies = {
      { "nvim-telescope/telescope.nvim", version = "*", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    opts = {
      options = {},
      search = {},
    },
  }
end

return M
