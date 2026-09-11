-- Adapter: LifetimePort -> tracks exit reason and runs cleanup handlers.
-- The composition root drives it: set the reason on completion or crash,
-- then shutdown() runs every registered handler exactly once.

local M = {}
M.__index = M

-- Reuse the domain port's reasons so there is one source of truth.
M.REASON = require("domain.ports.lifetime").REASON

function M.new()
  return setmetatable({
    cleanups = {},
    exit_handlers = {},
    reason = nil,
    shutting_down = false,
  }, M)
end

function M:register_cleanup(handler)
  table.insert(self.cleanups, handler)
end

function M:on_exit(handler)
  table.insert(self.exit_handlers, handler)
end

function M:get_exit_reason()
  return self.reason
end

function M:is_shutting_down()
  return self.shutting_down
end

function M:set_reason(reason)
  self.reason = reason
end

function M:shutdown(reason)
  if self.shutting_down then
    return
  end
  self.shutting_down = true
  self.reason = reason or self.reason or M.REASON.NORMAL

  for index = #self.exit_handlers, 1, -1 do
    pcall(self.exit_handlers[index], self.reason)
  end
  for index = #self.cleanups, 1, -1 do
    pcall(self.cleanups[index])
  end
end

return M
