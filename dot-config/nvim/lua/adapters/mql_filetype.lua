-- Adapter: MQL Filetype Support
-- Implements: implicit language support port
-- Plugin: riodelphino/mql-filetype.nvim
--
-- This adapter adds MetaTrader QL filetype detection.

local M = {}

--- Build lazy.nvim spec from domain + port
function M.spec()
  local mql = require("domain.languages").mql
  if not mql.filetype then return nil end

  return {
    "riodelphino/mql-filetype.nvim",
    lazy = false,
    opts = {},
  }
end

return M
