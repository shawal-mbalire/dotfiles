-- Adapter: TimePort -> wall-clock process timer.
-- Uses Linux /proc/uptime (monotonic, millisecond precision); falls back to
-- os.time() on other platforms. os.clock() is deliberately avoided: it reports
-- CPU time, which under-reports elapsed wall time.

local M = {}
M.__index = M

local UPTIME_PATH = "/proc/uptime"

function M.new()
  return setmetatable({}, M)
end

local function read_uptime_ms()
  local file = io.open(UPTIME_PATH, "r")
  if not file then
    return nil
  end
  local line = file:read("*l")
  file:close()
  if not line then
    return nil
  end
  local seconds = tonumber(line:match("^(%d+%.?%d*)"))
  if not seconds then
    return nil
  end
  return math.floor(seconds * 1000)
end

function M:now_ms()
  return read_uptime_ms() or (os.time() * 1000)
end

function M:elapsed_ms(start_ms)
  return self:now_ms() - start_ms
end

return M
