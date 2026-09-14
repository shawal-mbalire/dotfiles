-- Adapter: translates domain operations into hl.* API calls.
-- Implements the Hyprland ports: monitor, environment, input, binding,
-- command, visual, layer, runtime. Config is injected by the composition root.

local mappings = require("adapters.hyprland_mappings")

local A = {}
A.__index = A

function A.new(hl)
  assert(hl, "hyprland adapter requires the hl table")
  assert(hl.dsp, "hyprland adapter requires hl.dsp")
  assert(hl.exec_cmd, "hyprland adapter requires hl.exec_cmd")
  return setmetatable({ hl = hl, dsp = hl.dsp }, A)
end

-- MonitorPort
function A:apply_monitor(display)
  self.hl.monitor(mappings.to_monitor_rule(display))
end

-- EnvironmentPort
function A:set_env(name, value)
  self.hl.env(name, value)
end

-- InputPort
function A:configure_input(settings)
  self.hl.config(mappings.to_input_config(settings))
end

function A:configure_device(device)
  self.hl.device(mappings.to_device(device))
end

-- BindingPort
function A:register_bind(bind)
  local dispatcher = mappings.resolve(bind.action, self.dsp)
  self.hl.bind(mappings.to_key(bind.mods, bind.key), dispatcher, bind.opts)
end

function A:register_binds(binds)
  for _, bind in ipairs(binds) do
    self:register_bind(bind)
  end
end

-- CommandPort (immediate execution, distinct from bind dispatchers)
function A:run_command(command)
  return self.hl.exec_cmd(command)
end

-- VisualPort
function A:configure_visual(settings)
  self.hl.config(mappings.to_visual_config(settings))
end

function A:register_curve(bezier)
  self.hl.curve(bezier.name, { type = bezier.type, points = bezier.points })
end

function A:register_animation(anim)
  self.hl.animation(anim)
end

-- LayerPort
function A:apply_layer_rule(rule)
  self.hl.layer_rule(rule)
end

-- WindowRulePort
function A:apply_window_rule(rule)
  self.hl.window_rule(rule)
end

-- RuntimePort
function A:on_event(event, callback)
  self.hl.on(event, callback)
end

return A
