-- Port: WallpaperPort — render wallpaper config and keep the daemon alive

local M = {}
M.NAME = "WallpaperPort"

function M.configure(wallpapers)
  error("WallpaperPort.configure is not implemented")
end

function M.ensure_running()
  error("WallpaperPort.ensure_running is not implemented")
end

return M
