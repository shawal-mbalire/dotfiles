-- Pure mapping helpers: Wallpaper models -> hyprpaper config text.
-- No I/O here, so these are trivially unit-testable.

local M = {}

local function render_wallpaper(wallpaper)
  -- hyprpaper (>=0.8) requires `monitor` as the first key of the anonymous
  -- `wallpaper { }` category; an empty value means "fallback for all outputs".
  local monitors = wallpaper.monitors
  if #monitors == 0 then
    monitors = { "" }
  end

  local blocks = {}
  for _, monitor in ipairs(monitors) do
    local lines = {
      "wallpaper {",
      "    monitor =" .. (monitor ~= "" and (" " .. monitor) or ""),
      "    path = " .. wallpaper.path,
      "    fit_mode = " .. wallpaper.fit_mode,
      "}",
    }
    table.insert(blocks, table.concat(lines, "\n"))
  end
  return table.concat(blocks, "\n")
end

function M.render_conf(wallpapers)
  local blocks = { "splash = false", "ipc = on" }
  local preloaded = {}

  for _, wallpaper in ipairs(wallpapers) do
    if not preloaded[wallpaper.path] then
      table.insert(blocks, "preload = " .. wallpaper.path)
      preloaded[wallpaper.path] = true
    end
  end

  for _, wallpaper in ipairs(wallpapers) do
    table.insert(blocks, render_wallpaper(wallpaper))
  end

  return table.concat(blocks, "\n") .. "\n"
end

-- Idempotent daemon-ensure command: launch only when not already running.
function M.ensure_command(conf_path)
  return string.format("pgrep -x hyprpaper >/dev/null || hyprpaper -c %q", conf_path)
end

return M
