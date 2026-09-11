local fake_hl = require("tests.fixtures.fake_hl")
local mappings = require("adapters.hyprland_mappings")
local models = require("domain.models")

return {
  {
    name = "to_key_with_mods",
    run = function()
      assert(mappings.to_key("SUPER", "Q") == "SUPER + Q", "mods joining wrong")
    end,
  },
  {
    name = "to_key_without_mods",
    run = function()
      assert(mappings.to_key("", "Print") == "Print", "empty mods wrong")
      assert(mappings.to_key(nil, "Print") == "Print", "nil mods wrong")
    end,
  },
  {
    name = "to_monitor_rule_maps_display",
    run = function()
      local rule = mappings.to_monitor_rule(models.Display.new("eDP-1", "m", "p", 1))
      assert(rule.output == "eDP-1" and rule.mode == "m" and rule.position == "p" and rule.scale == 1, "rule wrong")
      assert(rule.mirror == nil, "mirror should be absent")
    end,
  },
  {
    name = "to_monitor_rule_includes_mirror",
    run = function()
      local rule = mappings.to_monitor_rule(models.Display.new("HDMI-A-2", "highres", "0x0", 1, "eDP-1"))
      assert(rule.mirror == "eDP-1", "mirror not mapped")
    end,
  },
  {
    name = "resolve_exec_cmd",
    run = function()
      local dsp = fake_hl.new().dsp
      local d = mappings.resolve({ type = "exec_cmd", args = "kitty" }, dsp)
      assert(d.name == "dsp.exec_cmd" and d.args[1] == "kitty", "exec dispatcher wrong")
    end,
  },
  {
    name = "resolve_focus",
    run = function()
      local dsp = fake_hl.new().dsp
      local d = mappings.resolve({ type = "focus", opts = { direction = "l" } }, dsp)
      assert(d.name == "dsp.focus" and d.args[1].direction == "l", "focus dispatcher wrong")
    end,
  },
  {
    name = "resolve_window_move",
    run = function()
      local dsp = fake_hl.new().dsp
      local d = mappings.resolve({ type = "window", action = "move", opts = { direction = "d" } }, dsp)
      assert(d.name == "dsp.window.move" and d.args[1].direction == "d", "window move wrong")
    end,
  },
  {
    name = "resolve_window_resize_with_coords",
    run = function()
      local dsp = fake_hl.new().dsp
      local d = mappings.resolve({ type = "window", action = "resize", opts = { x = 20, y = 0, relative = true } }, dsp)
      assert(d.name == "dsp.window.resize" and d.args[1].x == 20, "resize coords wrong")
    end,
  },
  {
    name = "resolve_window_resize_without_coords_is_mouse_resize",
    run = function()
      local dsp = fake_hl.new().dsp
      local d = mappings.resolve({ type = "window", action = "resize", opts = {} }, dsp)
      assert(d.name == "dsp.window.resize" and #d.args == 0, "mouse resize should pass no args")
    end,
  },
  {
    name = "resolve_workspace_toggle_special",
    run = function()
      local dsp = fake_hl.new().dsp
      local d = mappings.resolve({ type = "workspace", opts = { toggle_special = true, name = "magic" } }, dsp)
      assert(d.name == "dsp.workspace.toggle_special" and d.args[1] == "magic", "toggle special wrong")
    end,
  },
  {
    name = "resolve_workspace_move_monitor",
    run = function()
      local dsp = fake_hl.new().dsp
      local d = mappings.resolve({ type = "workspace", opts = { move = true, monitor = "l" } }, dsp)
      assert(d.name == "dsp.workspace.move" and d.args[1].monitor == "l", "workspace move wrong")
    end,
  },
  {
    name = "resolve_unknown_action_fails_loud",
    run = function()
      local dsp = fake_hl.new().dsp
      local ok, err = pcall(mappings.resolve, { type = "nonsense" }, dsp)
      assert(not ok, "expected failure for unknown action")
      assert(tostring(err):find("unknown bind action type"), "unhelpful error: " .. tostring(err))
    end,
  },
  {
    name = "resolve_unknown_window_action_fails_loud",
    run = function()
      local dsp = fake_hl.new().dsp
      local ok, err = pcall(mappings.resolve, { type = "window", action = "explode" }, dsp)
      assert(not ok, "expected failure for unknown window action")
      assert(tostring(err):find("unknown window action"), "unhelpful error: " .. tostring(err))
    end,
  },
  {
    name = "to_visual_config_builds_hyprland_sections",
    run = function()
      local active = models.Color.from_hex("89b4fa", 255)
      local settings = models.VisualSettings.new({
        gaps_in = 4, gaps_out = 5, border_size = 1, gradient_angle = 90,
        colors = { active = active, inactive = active, shadow = active },
        rounding = 3, rounding_power = 2, active_opacity = 1, inactive_opacity = 1,
        shadow_enabled = true, shadow_range = 4, shadow_render_power = 3,
        blur_enabled = true, blur_size = 3, blur_passes = 1, blur_vibrancy = 0.1,
        resize_on_border = false, allow_tearing = false,
        force_default_wallpaper = 0, disable_hyprland_logo = true,
      })
      local config = mappings.to_visual_config(settings)
      assert(config.general.gaps_in == 4, "general.gaps_in wrong")
      assert(config.general.col.active_border.angle == 90, "gradient angle wrong")
      assert(config.decoration.blur.size == 3, "decoration.blur wrong")
      assert(config.decoration.shadow.color == active.rgba, "shadow color wrong")
      assert(config.misc.disable_hyprland_logo == true, "misc wrong")
    end,
  },
  {
    name = "to_input_config_maps_domain_keyboard",
    run = function()
      local settings = models.InputSettings.new({
        keyboard = { layout = "gb,ara", variant = "", model = "", options = "caps", rules = "" },
        follow_mouse = 1, sensitivity = 0, touchpad = { natural_scroll = false },
      })
      local config = mappings.to_input_config(settings)
      assert(config.input.kb_layout == "gb,ara", "kb_layout wrong")
      assert(config.input.follow_mouse == 1, "follow_mouse wrong")
      assert(config.input.touchpad.natural_scroll == false, "touchpad wrong")
    end,
  },
  {
    name = "to_device_sets_authoritative_name_and_merges_opts",
    run = function()
      local device = models.Device.new("epic-mouse-v1", { name = "stale", sensitivity = -0.5 })
      local spec = mappings.to_device(device)
      assert(spec.name == "epic-mouse-v1", "name should be authoritative")
      assert(spec.sensitivity == -0.5, "opts not merged")
    end,
  },
}
