-- Port: TimePort — measure process duration (cross-cutting concern)

local M = {}
M.NAME = "TimePort"

function M.now_ms()
  error("TimePort.now_ms is not implemented")
end

function M.elapsed_ms(start_ms)
  error("TimePort.elapsed_ms is not implemented")
end

return M
