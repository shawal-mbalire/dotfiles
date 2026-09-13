-- Domain models (pure data, no side effects)

local constants = require("domain.constants")

local M = {}

M.Color = {}
M.Color.__index = M.Color

function M.Color.new(r, g, b, a)
  return setmetatable({ rgba = string.format("rgba(%02x%02x%02x%02x)", r, g, b, a or 255) }, M.Color)
end

function M.Color.from_hex(hex, alpha)
  hex = hex:gsub("^#", "")
  local r = tonumber(string.sub(hex, 1, 2), 16)
  local g = tonumber(string.sub(hex, 3, 4), 16)
  local b = tonumber(string.sub(hex, 5, 6), 16)
  return M.Color.new(r, g, b, alpha)
end

function M.Color.gradient(c1, c2, angle)
  return { colors = { c1.rgba, c2.rgba }, angle = angle or 0 }
end

M.Bezier = {}
M.Bezier.__index = M.Bezier

function M.Bezier.new(name, points)
  return setmetatable({ name = name, type = "bezier", points = points }, M.Bezier)
end

M.Anim = {}
M.Anim.__index = M.Anim

function M.Anim.new(leaf, speed, bezier, style)
  return setmetatable({ leaf = leaf, enabled = true, speed = speed, bezier = bezier, style = style }, M.Anim)
end

M.Display = {}
M.Display.__index = M.Display

function M.Display.new(output, mode, pos, scale, mirror)
  return setmetatable({ output = output, mode = mode, position = pos, scale = scale or 1, mirror = mirror }, M.Display)
end

M.Bind = {}
M.Bind.__index = M.Bind

function M.Bind.new(mods, key, action, opts)
  return setmetatable({ mods = mods or "", key = key, action = action, opts = opts or {} }, M.Bind)
end

function M.Bind.exec(cmd)
  return { type = constants.ACTION.EXEC_CMD, args = cmd }
end

function M.Bind.window(action, opts)
  return { type = constants.ACTION.WINDOW, action = action, opts = opts or {} }
end

function M.Bind.focus(opts)
  return { type = constants.ACTION.FOCUS, opts = opts }
end

function M.Bind.workspace(opts)
  return { type = constants.ACTION.WORKSPACE, opts = opts }
end

M.LayerRule = {}
M.LayerRule.__index = M.LayerRule

function M.LayerRule.new(match, opts)
  local r = setmetatable({ match = match, blur = false }, M.LayerRule)
  if opts then for k, v in pairs(opts) do r[k] = v end end
  return r
end

-- Visual/appearance settings (domain shape, flat fields).
-- Mapping to the compositor's `general`/`decoration`/`misc` sections is an
-- adapter concern (see adapters/hyprland_mappings.lua).
M.VisualSettings = {}
M.VisualSettings.__index = M.VisualSettings

function M.VisualSettings.new(spec)
  return setmetatable({
    gaps_in = spec.gaps_in,
    gaps_out = spec.gaps_out,
    border_size = spec.border_size,
    colors = spec.colors,
    gradient_angle = spec.gradient_angle,
    resize_on_border = spec.resize_on_border,
    allow_tearing = spec.allow_tearing,
    rounding = spec.rounding,
    rounding_power = spec.rounding_power,
    active_opacity = spec.active_opacity,
    inactive_opacity = spec.inactive_opacity,
    shadow_enabled = spec.shadow_enabled,
    shadow_range = spec.shadow_range,
    shadow_render_power = spec.shadow_render_power,
    blur_enabled = spec.blur_enabled,
    blur_size = spec.blur_size,
    blur_passes = spec.blur_passes,
    blur_vibrancy = spec.blur_vibrancy,
    force_default_wallpaper = spec.force_default_wallpaper,
    disable_hyprland_logo = spec.disable_hyprland_logo,
  }, M.VisualSettings)
end

-- Input settings (domain shape).
M.InputSettings = {}
M.InputSettings.__index = M.InputSettings

function M.InputSettings.new(spec)
  return setmetatable({
    keyboard = spec.keyboard or {},
    follow_mouse = spec.follow_mouse,
    sensitivity = spec.sensitivity,
    touchpad = spec.touchpad,
  }, M.InputSettings)
end

-- Pointer/touchpad device (domain shape).
M.Device = {}
M.Device.__index = M.Device

function M.Device.new(name, opts)
  return setmetatable({ name = name, opts = opts or {} }, M.Device)
end

-- Wallpaper (domain shape).
-- An empty `monitors` list means "every monitor".
M.Wallpaper = {}
M.Wallpaper.__index = M.Wallpaper

function M.Wallpaper.new(spec)
  assert(spec and spec.path, "Wallpaper requires a path")
  return setmetatable({
    path = spec.path,
    fit_mode = spec.fit_mode or constants.WALLPAPER_FIT.DEFAULT,
    monitors = spec.monitors or {},
  }, M.Wallpaper)
end

return M
