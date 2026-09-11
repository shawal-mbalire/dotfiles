-- Port: RuntimePort — subscribe to compositor lifecycle events

local M = {}
M.NAME = "RuntimePort"

function M.on_event(event, callback)
  error("RuntimePort.on_event is not implemented")
end

return M
