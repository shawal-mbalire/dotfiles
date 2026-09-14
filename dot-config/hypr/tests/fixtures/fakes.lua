-- Test fixtures: in-memory fakes implementing the domain ports.

local M = {}

-- Fake LoggerPort
local Logger = {}
Logger.__index = Logger

function M.new_logger()
  return setmetatable({ records = {} }, Logger)
end

function Logger:debug(message, fields) self:_record("debug", message, fields) end
function Logger:info(message, fields) self:_record("info", message, fields) end
function Logger:warn(message, fields) self:_record("warn", message, fields) end
function Logger:error(message, fields) self:_record("error", message, fields) end

function Logger:_record(level, message, fields)
  table.insert(self.records, { level = level, message = message, fields = fields })
end

function Logger:count(level)
  local n = 0
  for _, record in ipairs(self.records) do
    if record.level == level then n = n + 1 end
  end
  return n
end

function Logger:has_message(message)
  for _, record in ipairs(self.records) do
    if record.message == message then return true end
  end
  return false
end

-- Fake TimePort
local Time = {}
Time.__index = Time

function M.new_time()
  return setmetatable({ current_ms = 0 }, Time)
end

function Time:now_ms() return self.current_ms end
function Time:elapsed_ms(start_ms) return self.current_ms - start_ms end
function Time:advance_ms(ms) self.current_ms = self.current_ms + ms end

-- Fake LifetimePort (mirrors the real adapter: handlers run once, in reverse)
local Lifetime = {}
Lifetime.__index = Lifetime
Lifetime.REASON = require("domain.ports.lifetime").REASON

function M.new_lifetime()
  return setmetatable({ cleanups = {}, exits = {}, reason = nil, shutting_down = false }, Lifetime)
end

function Lifetime:register_cleanup(handler) table.insert(self.cleanups, handler) end
function Lifetime:on_exit(handler) table.insert(self.exits, handler) end
function Lifetime:get_exit_reason() return self.reason end
function Lifetime:is_shutting_down() return self.shutting_down end
function Lifetime:set_reason(reason) self.reason = reason end

function Lifetime:shutdown(reason)
  if self.shutting_down then
    return
  end
  self.shutting_down = true
  self.reason = reason or self.reason or Lifetime.REASON.NORMAL

  for index = #self.exits, 1, -1 do
    self.exits[index](self.reason)
  end
  for index = #self.cleanups, 1, -1 do
    self.cleanups[index]()
  end
end

-- Fake WallpaperPort (records each configure call)
local Wallpaper = {}
Wallpaper.__index = Wallpaper

function M.new_wallpaper()
  return setmetatable({ calls = {}, ensured = 0 }, Wallpaper)
end

function Wallpaper:configure(wallpapers)
  table.insert(self.calls, { wallpapers = wallpapers })
end

function Wallpaper:ensure_running() self.ensured = self.ensured + 1 end

function Wallpaper:count() return #self.calls end
function Wallpaper:last() return self.calls[#self.calls] end

-- Fake Hyprland ports (one object implements every Hyprland port, like prod)
local Hypr = {}
Hypr.__index = Hypr

function M.new_hypr()
  return setmetatable({ calls = {} }, Hypr)
end

function Hypr:_call(name, ...)
  table.insert(self.calls, { name = name, args = { ... } })
end

function Hypr:apply_monitor(display) self:_call("apply_monitor", display) end
function Hypr:set_env(name, value) self:_call("set_env", name, value) end
function Hypr:configure_input(settings) self:_call("configure_input", settings) end
function Hypr:configure_device(spec) self:_call("configure_device", spec) end
function Hypr:register_bind(bind) self:_call("register_bind", bind) end
function Hypr:register_binds(binds) self:_call("register_binds", binds) end
function Hypr:run_command(command) self:_call("run_command", command) end
function Hypr:configure_visual(section) self:_call("configure_visual", section) end
function Hypr:register_curve(bezier) self:_call("register_curve", bezier) end
function Hypr:register_animation(anim) self:_call("register_animation", anim) end
function Hypr:apply_layer_rule(rule) self:_call("apply_layer_rule", rule) end
function Hypr:apply_window_rule(rule) self:_call("apply_window_rule", rule) end
function Hypr:on_event(event, callback) self:_call("on_event", event, callback) end

function Hypr:find(name)
  local out = {}
  for _, call in ipairs(self.calls) do
    if call.name == name then table.insert(out, call) end
  end
  return out
end

function Hypr:count(name)
  return #self:find(name)
end

-- Deterministic sample config (never reads env, never touches infra)
function M.sample_config()
  return {
    log_level = "debug",
    profile = "desktop",
    laptop = false,
    mainMod = "SUPER",
    apps = {
      terminal = "kitty", browser = "zen", file_manager = "nautilus",
      menu = "fuzzel", note_taker = "obsidian", editor = "code-insiders",
      audio = "pavucontrol", bar_toggle = "toggle_bar", display_toggle = "toggle_display",
    },
    commands = {
      volume_up = "vol up", volume_down = "vol down", volume_mute = "vol mute",
      mic_mute = "mic mute", brightness_up = "bright up", brightness_down = "bright down",
      media_next = "next", media_play = "play", media_prev = "prev",
      clipboard = "clip", notify_toggle = "notif on", notify_dismiss = "notif off",
      screenshot = "shot",
    },
    displays = {
      { output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1 },
      { output = "HDMI-A-2", mode = "highres", position = "0x0", scale = 1, mirror = "eDP-1" },
    },
    input = {
      kb_layout = "gb", kb_variant = "", kb_model = "", kb_options = "opts", kb_rules = "",
      follow_mouse = 1, sensitivity = 0, touchpad = { natural_scroll = false },
      mouse = { name = "epic-mouse-v1", sensitivity = -0.5 },
    },
    visual = {
      gaps_in = 4, gaps_out = 5, border_size = 1, rounding = 5, rounding_power = 2,
      gradient_angle = 90, active_opacity = 1.0, inactive_opacity = 1.0,
      shadow_enabled = true, shadow_range = 4, shadow_render_power = 3,
      blur_enabled = true, blur_size = 3, blur_passes = 1, blur_vibrancy = 0.1696,
      resize_on_border = false, allow_tearing = false,
      force_default_wallpaper = 0, disable_hyprland_logo = true,
    },
    colors = {
      active = { hex = "89b4fa", alpha = 255 },
      inactive = { hex = "45475a", alpha = 238 },
      shadow = { hex = "1a1a1a", alpha = 238 },
    },
    env = { XCURSOR_SIZE = "24", HYPRCURSOR_SIZE = "24" },
    wallpaper = {
      conf_path = "/tmp/hyprpaper-test.conf",
      wallpapers = {
        { path = "/tmp/wall.jpg", fit_mode = "cover", monitors = { "eDP-1" } },
      },
    },
    autostart = { "nm-applet", "swaync" },
  }
end

-- Build a full deps table wired to fakes (mirrors the composition root)
function M.deps(overrides)
  local hypr = M.new_hypr()
  local deps = {
    config = M.sample_config(),
    logger = M.new_logger(),
    time = M.new_time(),
    lifetime = M.new_lifetime(),
    monitor = hypr,
    environment = hypr,
    input = hypr,
    binding = hypr,
    command = hypr,
    visual = hypr,
    layer = hypr,
    window_rule = hypr,
    runtime = hypr,
    hypr = hypr,
    wallpaper = M.new_wallpaper(),
  }
  if overrides then
    for key, value in pairs(overrides) do
      deps[key] = value
    end
  end
  return deps
end

return M
