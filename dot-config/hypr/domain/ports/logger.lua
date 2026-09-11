-- Port: LoggerPort — structured logging (cross-cutting concern)

local M = {}
M.NAME = "LoggerPort"

function M.debug(message, fields)
  error("LoggerPort.debug is not implemented")
end

function M.info(message, fields)
  error("LoggerPort.info is not implemented")
end

function M.warn(message, fields)
  error("LoggerPort.warn is not implemented")
end

function M.error(message, fields)
  error("LoggerPort.error is not implemented")
end

return M
