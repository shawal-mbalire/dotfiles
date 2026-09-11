-- Port: LifetimePort — track exit reason and run cleanup (cross-cutting concern)
-- M.REASON is the single source of truth for exit reasons; adapters must reuse it.

local M = {}
M.NAME = "LifetimePort"

M.REASON = {
  NORMAL = "normal",
  USER_EXIT = "user_exit",
  CRASH = "crash",
  TIMEOUT = "timeout",
  SHUTDOWN = "shutdown",
}

function M.register_cleanup(handler)
  error("LifetimePort.register_cleanup is not implemented")
end

function M.on_exit(handler)
  error("LifetimePort.on_exit is not implemented")
end

function M.get_exit_reason()
  error("LifetimePort.get_exit_reason is not implemented")
end

function M.is_shutting_down()
  error("LifetimePort.is_shutting_down is not implemented")
end

-- Driver-facing: set the reason before shutdown, then run handlers exactly once.
function M.set_reason(reason)
  error("LifetimePort.set_reason is not implemented")
end

function M.shutdown(reason)
  error("LifetimePort.shutdown is not implemented")
end

return M
