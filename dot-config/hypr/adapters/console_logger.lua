-- Adapter: LoggerPort -> structured console logger.
-- Sink and level are constructor-injected so tests can capture output.

local M = {}
M.__index = M

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }

local function default_sink()
  if io and io.stderr then
    return io.stderr
  end
  return { write = function() end }
end

function M.new(opts)
  opts = opts or {}
  return setmetatable({
    min_level = opts.min_level or "info",
    sink = opts.sink or default_sink(),
    prefix = opts.prefix or "[hypr]",
  }, M)
end

function M:_log(level, message, fields)
  if (LEVELS[level] or 0) < (LEVELS[self.min_level] or 0) then
    return
  end

  local parts = { string.format("%s %-5s %s", self.prefix, level:upper(), message) }
  if fields then
    local keys = {}
    for key in pairs(fields) do
      keys[#keys + 1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
      local value = tostring(fields[key])
      if value:find("%s") then
        value = string.format("%q", value)
      end
      parts[#parts + 1] = string.format("%s=%s", key, value)
    end
  end
  self.sink:write(table.concat(parts, " ") .. "\n")
end

function M:debug(message, fields) self:_log("debug", message, fields) end
function M:info(message, fields) self:_log("info", message, fields) end
function M:warn(message, fields) self:_log("warn", message, fields) end
function M:error(message, fields) self:_log("error", message, fields) end

return M
