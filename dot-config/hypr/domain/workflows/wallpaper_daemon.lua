-- Workflow: ensure the wallpaper daemon is running (idempotent).
-- Wired to hyprland.start and config.reloaded so a reload self-heals.
-- The adapter owns the "how" (launch command); the domain only asks.

return function(deps)
  local started = deps.time:now_ms()
  deps.wallpaper:ensure_running()
  deps.logger:debug("wallpaper_daemon_ensured", { elapsed_ms = deps.time:elapsed_ms(started) })
end
