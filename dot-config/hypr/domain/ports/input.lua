-- Port: InputPort — configure keyboard/pointer and per-device settings

local M = {}
M.NAME = "InputPort"

function M.configure_input(settings)
  error("InputPort.configure_input is not implemented")
end

function M.configure_device(spec)
  error("InputPort.configure_device is not implemented")
end

return M
