-- Workflow: ensure the wallpaper daemon is running (idempotent).
-- Wired to hyprland.start and config.reloaded so a reload self-heals.
-- The adapter owns the "how" (launch command); the domain only asks.

return function(deps)
  deps.wallpaper:ensure_running()
  deps.logger:debug("wallpaper_daemon_ensured")
end
