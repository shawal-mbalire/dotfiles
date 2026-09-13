-- Adapter: owns the hyprpaper daemon's lifecycle and config.
-- Implements WallpaperPort. Conf path and the CommandPort are injected by the
-- composition root; no env access and no I/O against a live compositor here.

local mappings = require("adapters.hyprpaper_mappings")

local A = {}
A.__index = A

function A.new(spec)
  assert(spec and spec.conf_path, "hyprpaper adapter requires a conf path")
  assert(
    spec.command and type(spec.command.run_command) == "function",
    "hyprpaper adapter requires a CommandPort"
  )
  return setmetatable({ conf_path = spec.conf_path, command = spec.command }, A)
end

function A:configure(wallpapers)
  local handle, err = io.open(self.conf_path, "w")
  if not handle then
    error("hyprpaper adapter failed to write " .. self.conf_path .. ": " .. tostring(err))
  end
  handle:write(mappings.render_conf(wallpapers))
  handle:close()
end

function A:ensure_running()
  self.command:run_command(mappings.ensure_command(self.conf_path))
end

return A
