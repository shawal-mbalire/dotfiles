-- Pure mapping helpers: domain models -> external wire formats.
-- No I/O here, so these are trivially unit-testable with fakes.

local constants = require("domain.constants")
local models = require("domain.models")

local M = {}

-- Display model -> Hyprland monitor rule table (DTO boundary)
function M.to_monitor_rule(display)
  local rule = {
    output   = display.output,
    mode     = display.mode,
    position = display.position,
    scale    = display.scale,
  }
  if display.mirror then
    rule.mirror = display.mirror
  end
  return rule
end

-- VisualSettings model -> Hyprland `general`/`decoration`/`misc` sections
function M.to_visual_config(visual)
  local active = visual.colors.active
  local inactive = visual.colors.inactive
  local shadow = visual.colors.shadow

  return {
    general = {
      gaps_in = visual.gaps_in,
      gaps_out = visual.gaps_out,
      border_size = visual.border_size,
      col = {
        active_border = models.Color.gradient(active, active, visual.gradient_angle),
        inactive_border = inactive.rgba,
      },
      resize_on_border = visual.resize_on_border,
      allow_tearing = visual.allow_tearing,
    },
    decoration = {
      rounding = visual.rounding,
      rounding_power = visual.rounding_power,
      active_opacity = visual.active_opacity,
      inactive_opacity = visual.inactive_opacity,
      shadow = {
        enabled = visual.shadow_enabled,
        range = visual.shadow_range,
        render_power = visual.shadow_render_power,
        color = shadow.rgba,
      },
      blur = {
        enabled = visual.blur_enabled,
        size = visual.blur_size,
        passes = visual.blur_passes,
        vibrancy = visual.blur_vibrancy,
      },
    },
    animations = { enabled = true },
    misc = {
      force_default_wallpaper = visual.force_default_wallpaper,
      disable_hyprland_logo = visual.disable_hyprland_logo,
    },
  }
end

-- InputSettings model -> Hyprland `input` section
function M.to_input_config(input)
  local keyboard = input.keyboard or {}
  return {
    input = {
      kb_layout = keyboard.layout,
      kb_variant = keyboard.variant,
      kb_model = keyboard.model,
      kb_options = keyboard.options,
      kb_rules = keyboard.rules,
      follow_mouse = input.follow_mouse,
      sensitivity = input.sensitivity,
      touchpad = input.touchpad,
    },
  }
end

-- Device model -> Hyprland device spec (name is authoritative)
function M.to_device(device)
  local spec = {}
  for key, value in pairs(device.opts) do
    spec[key] = value
  end
  spec.name = device.name
  return spec
end

-- Bind modifiers + key -> single Hyprland key string
function M.to_key(mods, key)
  if mods == nil or mods == "" then
    return key
  end
  return mods .. " + " .. key
end

-- Bind action model -> a Hyprland dispatcher object (fed to hl.bind)
function M.resolve(action, dsp)
  local kind = action.type

  if kind == constants.ACTION.EXEC_CMD then
    return dsp.exec_cmd(action.args)
  elseif kind == constants.ACTION.WINDOW then
    return M.resolve_window(action, dsp)
  elseif kind == constants.ACTION.FOCUS then
    return dsp.focus(action.opts)
  elseif kind == constants.ACTION.WORKSPACE then
    return M.resolve_workspace(action, dsp)
  end

  error("unknown bind action type: " .. tostring(kind))
end

function M.resolve_window(action, dsp)
  local name = action.action
  local opts = action.opts or {}

  if name == constants.WINDOW_ACTION.MOVE then
    return dsp.window.move(opts)
  elseif name == constants.WINDOW_ACTION.FLOAT then
    return dsp.window.float()
  elseif name == constants.WINDOW_ACTION.CLOSE then
    return dsp.window.close()
  elseif name == constants.WINDOW_ACTION.PSEUDO then
    return dsp.window.pseudo()
  elseif name == constants.WINDOW_ACTION.DRAG then
    return dsp.window.drag()
  elseif name == constants.WINDOW_ACTION.RESIZE then
    if opts.x and opts.y then
      return dsp.window.resize(opts)
    end
    return dsp.window.resize()
  end

  error("unknown window action: " .. tostring(name))
end

function M.resolve_workspace(action, dsp)
  local opts = action.opts or {}

  if opts.toggle_special then
    return dsp.workspace.toggle_special(opts.name)
  elseif opts.move then
    return dsp.workspace.move({ monitor = opts.monitor })
  end
  return dsp.focus(opts)
end

return M
