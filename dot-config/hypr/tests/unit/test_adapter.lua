local fake_hl = require("tests.fixtures.fake_hl")
local fakes = require("tests.fixtures.fakes")
local Adapter = require("adapters.hyprland_adapter")
local HyprpaperAdapter = require("adapters.hyprpaper_adapter")
local models = require("domain.models")
local verify = require("domain.ports.verify")

local function hyprpaper(conf_path)
  return HyprpaperAdapter.new({ conf_path = conf_path, command = fakes.new_hypr() })
end

return {
  {
    name = "adapter_conforms_to_every_hypr_port",
    run = function()
      local adapter = Adapter.new(fake_hl.new())
      verify.assert_ports(adapter, verify.HYPR_PORTS)
    end,
  },
  {
    name = "hyprpaper_adapter_conforms_to_wallpaper_port",
    run = function()
      verify.assert_port(hyprpaper("/tmp/hyprpaper-adapter.conf"), verify.wallpaper)
    end,
  },
  {
    name = "hyprpaper_adapter_writes_rendered_conf",
    run = function()
      local path = os.tmpname()
      local adapter = hyprpaper(path)
      adapter:configure({ models.Wallpaper.new({ path = "/tmp/w.jpg", monitors = { "eDP-1" } }) })

      local handle = assert(io.open(path, "r"), "conf was not written")
      local written = handle:read("*a")
      handle:close()
      os.remove(path)

      assert(written:find("preload = /tmp/w.jpg", 1, true), "conf missing preload")
      assert(written:find("path = /tmp/w.jpg", 1, true), "conf missing wallpaper block")
    end,
  },
  {
    name = "hyprpaper_adapter_ensure_running_runs_daemon_command",
    run = function()
      local command = fakes.new_hypr()
      local adapter = HyprpaperAdapter.new({ conf_path = "/tmp/x.conf", command = command })
      adapter:ensure_running()
      local call = command:find("run_command")[1]
      assert(call, "daemon ensure command not run")
      assert(call.args[1]:find("pgrep -x hyprpaper", 1, true), "missing idempotent guard")
    end,
  },
  {
    name = "hyprpaper_adapter_requires_conf_path_and_command_port",
    run = function()
      assert(not pcall(HyprpaperAdapter.new, nil), "adapter without deps must fail loud")
      assert(not pcall(HyprpaperAdapter.new, { conf_path = "/tmp/x.conf" }), "adapter without command port must fail loud")
    end,
  },
  {
    name = "apply_monitor_maps_display_model_to_rule",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      adapter:apply_monitor(models.Display.new("eDP-1", "1920x1200@60", "0x0", 1))
      local rule = hl:find("monitor")[1].args[1]
      assert(rule.output == "eDP-1", "output not translated: " .. tostring(rule.output))
      assert(rule.mirror == nil, "mirror should be absent")
    end,
  },
  {
    name = "register_bind_resolves_dispatcher_and_key",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      adapter:register_bind(models.Bind.new("SUPER", "Q", models.Bind.window("close")))
      local call = hl:find("bind")[1]
      assert(call, "hl.bind not called")
      assert(call.args[1] == "SUPER + Q", "key wrong: " .. tostring(call.args[1]))
      assert(call.args[2].name == "dsp.window.close", "dispatcher wrong")
    end,
  },
  {
    name = "register_bind_without_mods_uses_bare_key",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      adapter:register_bind(models.Bind.new("", "Print", models.Bind.exec("shot")))
      assert(hl:find("bind")[1].args[1] == "Print", "bare key wrong")
    end,
  },
  {
    name = "run_command_uses_hl_exec_cmd_not_a_bind_dispatcher",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      adapter:run_command("nm-applet")
      local call = hl:find("exec_cmd")[1]
      assert(call and call.args[1] == "nm-applet", "hl.exec_cmd not called")
      assert(#hl:find("dsp.exec_cmd") == 0, "run_command must not build a bind dispatcher")
    end,
  },
  {
    name = "register_curve_passes_name_type_and_points",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      adapter:register_curve(models.Bezier.new("ease", { { 0, 0 }, { 1, 1 } }))
      local call = hl:find("curve")[1]
      assert(call.args[1] == "ease", "curve name wrong")
      assert(call.args[2].type == "bezier", "curve type wrong")
      assert(#call.args[2].points == 2, "curve points wrong")
    end,
  },
  {
    name = "apply_layer_rule_passes_domain_rule_through",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      adapter:apply_layer_rule(models.LayerRule.new({ namespace = "waybar" }, { blur = true }))
      local rule = hl:find("layer_rule")[1].args[1]
      assert(rule.match.namespace == "waybar", "layer match wrong")
      assert(rule.blur == true, "layer opts not merged")
    end,
  },
  {
    name = "configure_visual_maps_domain_settings_to_sections",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      local color = models.Color.from_hex("89b4fa", 255)
      adapter:configure_visual(models.VisualSettings.new({
        gaps_in = 4, gaps_out = 5, border_size = 1, gradient_angle = 90,
        colors = { active = color, inactive = color, shadow = color },
        rounding = 3, rounding_power = 2, active_opacity = 1, inactive_opacity = 1,
        shadow_enabled = true, shadow_range = 4, shadow_render_power = 3,
        blur_enabled = true, blur_size = 3, blur_passes = 1, blur_vibrancy = 0.1,
      }))
      local section = hl:find("config")[1].args[1]
      assert(section.general.gaps_in == 4, "general section not mapped")
      assert(section.decoration.blur.enabled == true, "decoration section not mapped")
    end,
  },
  {
    name = "configure_input_maps_domain_settings_to_input_section",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      adapter:configure_input(models.InputSettings.new({
        keyboard = { layout = "gb,ara" }, follow_mouse = 1,
      }))
      local section = hl:find("config")[1].args[1]
      assert(section.input.kb_layout == "gb,ara", "input section not mapped")
    end,
  },
  {
    name = "configure_device_maps_domain_device",
    run = function()
      local hl = fake_hl.new()
      local adapter = Adapter.new(hl)
      adapter:configure_device(models.Device.new("epic-mouse-v1", { sensitivity = -0.5 }))
      local spec = hl:find("device")[1].args[1]
      assert(spec.name == "epic-mouse-v1" and spec.sensitivity == -0.5, "device not mapped")
    end,
  },
}
