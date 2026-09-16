-- Port: Session Persistence
-- Contract: Session adapter must provide save/load/stop.
--
-- Domain requirement: "I want sessions saved and restored automatically."
-- Adapter options: persistence.nvim, auto-session, etc.

local M = {}

--- Expected adapter shape:
--- @class SessionPort
---   event: string  -- lazy.nvim event trigger
---   opts: table    -- plugin options

function M.default()
  local session = require("domain.editor").session
  if not session.enabled then
    return nil
  end
  return {
    event = "BufReadPre",
    opts = {},
  }
end

return M
