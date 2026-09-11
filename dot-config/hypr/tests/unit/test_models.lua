local models = require("domain.models")

return {
  {
    name = "color_new_formats_rgba_with_default_alpha",
    run = function()
      local c = models.Color.new(0x89, 0xb4, 0xfa)
      assert(c.rgba == "rgba(89b4faff)", "got " .. tostring(c.rgba))
    end,
  },
  {
    name = "color_from_hex_strips_hash_and_applies_alpha",
    run = function()
      local c = models.Color.from_hex("#89b4fa", 0)
      assert(c.rgba == "rgba(89b4fa00)", "got " .. tostring(c.rgba))
    end,
  },
  {
    name = "color_gradient_shape",
    run = function()
      local c = models.Color.from_hex("89b4fa", 255)
      local g = models.Color.gradient(c, c, 90)
      assert(g.angle == 90 and #g.colors == 2, "gradient shape wrong")
    end,
  },
  {
    name = "bezier_fields",
    run = function()
      local b = models.Bezier.new("ease", { { 0, 0 }, { 1, 1 } })
      assert(b.name == "ease" and b.type == "bezier" and #b.points == 2, "bezier wrong")
    end,
  },
  {
    name = "anim_enabled_by_default",
    run = function()
      local a = models.Anim.new("fade", 1, "linear", "popin 87%")
      assert(a.leaf == "fade" and a.enabled == true and a.style == "popin 87%", "anim wrong")
    end,
  },
  {
    name = "display_defaults_scale_and_mirror",
    run = function()
      local d = models.Display.new("eDP-1", "preferred", "auto")
      assert(d.scale == 1 and d.mirror == nil, "display defaults wrong")
    end,
  },
  {
    name = "bind_action_constructors",
    run = function()
      local exec = models.Bind.exec("kitty")
      assert(exec.type == "exec_cmd" and exec.args == "kitty", "exec action wrong")

      local win = models.Bind.window("close")
      assert(win.type == "window" and win.action == "close", "window action wrong")

      local focus = models.Bind.focus({ direction = "l" })
      assert(focus.type == "focus" and focus.opts.direction == "l", "focus action wrong")

      local ws = models.Bind.workspace({ move = true })
      assert(ws.type == "workspace" and ws.opts.move == true, "workspace action wrong")
    end,
  },
  {
    name = "bind_new_holds_action_and_opts",
    run = function()
      local b = models.Bind.new("SUPER", "Q", models.Bind.window("close"), { mouse = true })
      assert(b.mods == "SUPER" and b.key == "Q", "bind key wrong")
      assert(b.action.type == "window" and b.action.action == "close", "bind action wrong")
      assert(b.opts.mouse == true, "bind opts wrong")
    end,
  },
  {
    name = "layer_rule_merges_opts_over_defaults",
    run = function()
      local r = models.LayerRule.new({ namespace = "waybar" }, { blur = true, ignore_alpha = 0 })
      assert(r.match.namespace == "waybar", "match wrong")
      assert(r.blur == true and r.ignore_alpha == 0, "opts not merged")
    end,
  },
  {
    name = "visual_settings_carry_domain_fields",
    run = function()
      local v = models.VisualSettings.new({
        gaps_in = 4, gaps_out = 5, colors = { active = "a" }, gradient_angle = 90,
      })
      assert(v.gaps_in == 4 and v.gaps_out == 5 and v.gradient_angle == 90, "visual fields wrong")
      assert(v.colors.active == "a", "colors not carried")
    end,
  },
  {
    name = "input_settings_normalize_keyboard",
    run = function()
      local i = models.InputSettings.new({ keyboard = { layout = "gb" }, follow_mouse = 1 })
      assert(i.keyboard.layout == "gb", "keyboard not stored")
      assert(i.follow_mouse == 1, "follow_mouse not stored")
    end,
  },
  {
    name = "device_holds_name_and_opts",
    run = function()
      local d = models.Device.new("mouse", { sensitivity = -0.5 })
      assert(d.name == "mouse" and d.opts.sensitivity == -0.5, "device wrong")
    end,
  },
}
