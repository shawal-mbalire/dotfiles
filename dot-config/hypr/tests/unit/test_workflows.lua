local fakes = require("tests.fixtures.fakes")

local displays = require("domain.workflows.displays")
local env = require("domain.workflows.env")
local look = require("domain.workflows.look")
local wallpaper = require("domain.workflows.wallpaper")
local wallpaper_daemon = require("domain.workflows.wallpaper_daemon")
local input = require("domain.workflows.input")
local keybindings = require("domain.workflows.keybindings")
local windows = require("domain.workflows.windows")
local autostart = require("domain.workflows.autostart")

return {
  {
    name = "displays_applies_each_display",
    run = function()
      local deps = fakes.deps()
      displays(deps)
      assert(deps.hypr:count("apply_monitor") == 2, "expected 2 monitors")
      assert(deps.logger:has_message("displays_configured"), "no completion log")
    end,
  },
  {
    name = "displays_uses_injected_config_not_globals",
    run = function()
      local deps = fakes.deps()
      deps.config.displays = { { output = "DP-1", mode = "preferred", position = "auto", scale = "auto" } }
      displays(deps)
      local display = deps.hypr:find("apply_monitor")[1].args[1]
      assert(display.output == "DP-1", "injected config ignored")
    end,
  },
  {
    name = "env_sets_every_variable",
    run = function()
      local deps = fakes.deps()
      env(deps)
      assert(deps.hypr:count("set_env") == 2, "expected 2 env vars")
    end,
  },
  {
    name = "look_configures_visual_curves_and_animations",
    run = function()
      local deps = fakes.deps()
      look(deps)
      assert(deps.hypr:count("configure_visual") == 1, "visual section missing")
      assert(deps.hypr:count("register_curve") == 5, "curves missing")
      assert(deps.hypr:count("register_animation") == 16, "animations missing")
    end,
  },
  {
    name = "wallpaper_configures_port_from_config",
    run = function()
      local deps = fakes.deps()
      wallpaper(deps)
      assert(deps.wallpaper:count() == 1, "wallpaper port not configured")
      local applied = deps.wallpaper:last().wallpapers
      assert(#applied == 1, "expected 1 wallpaper model")
      assert(applied[1].path == "/tmp/wall.jpg", "path not read from config")
      assert(applied[1].fit_mode == "cover", "fit_mode not carried")
      assert(deps.logger:has_message("wallpaper_configured"), "no wallpaper completion log")
    end,
  },
  {
    name = "wallpaper_daemon_ensures_running_via_port",
    run = function()
      local deps = fakes.deps()
      wallpaper_daemon(deps)
      assert(deps.wallpaper.ensured == 1, "wallpaper daemon not ensured")
      assert(deps.logger:has_message("wallpaper_daemon_ensured"), "no ensure log")
    end,
  },
  {
    name = "input_configures_keyboard_and_device_from_config",
    run = function()
      local deps = fakes.deps()
      input(deps)
      assert(deps.hypr:count("configure_input") == 1, "input missing")
      assert(deps.hypr:count("configure_device") == 1, "device missing")
      local device = deps.hypr:find("configure_device")[1].args[1]
      assert(device.name == "epic-mouse-v1", "device not read from config")
    end,
  },
  {
    name = "keybindings_registers_expected_count",
    run = function()
      local deps = fakes.deps()
      keybindings(deps)
      local list = deps.hypr:find("register_binds")[1].args[1]
      -- 13 apps + 3 window + 4 focus + 4 move + 4 resize + 4 monitor
      -- + 2 special + 4 mouse + 10 media + 2 screenshots + 20 workspaces = 70
      assert(#list == 70, "expected 70 binds, got " .. tostring(#list))
    end,
  },
  {
    name = "keybindings_workspace_10_maps_to_key_0",
    run = function()
      local deps = fakes.deps()
      keybindings(deps)
      local list = deps.hypr:find("register_binds")[1].args[1]
      for _, bind in ipairs(list) do
        if bind.key == "0" and bind.action.type == "focus" and bind.action.opts.workspace == "10" then
          return
        end
      end
      error("workspace 10 bind missing")
    end,
  },
  {
    name = "keybindings_use_commands_from_config",
    run = function()
      local deps = fakes.deps()
      deps.config.commands.volume_up = "CUSTOM_VOL"
      keybindings(deps)
      local list = deps.hypr:find("register_binds")[1].args[1]
      for _, bind in ipairs(list) do
        if bind.action.type == "exec_cmd" and bind.action.args == "CUSTOM_VOL" then
          return
        end
      end
      error("config command not used")
    end,
  },
  {
    name = "windows_applies_layer_and_window_rules",
    run = function()
      local deps = fakes.deps()
      windows(deps)
      assert(deps.hypr:count("apply_layer_rule") == 3, "expected 3 layer rules")
      assert(deps.hypr:count("apply_window_rule") == 1, "expected 1 window rule")
      assert(deps.logger:has_message("rules_applied"), "no rules completion log")
    end,
  },
  {
    name = "autostart_runs_every_command",
    run = function()
      local deps = fakes.deps()
      autostart(deps)
      assert(deps.hypr:count("run_command") == 2, "autostart commands did not run")
      assert(deps.logger:has_message("autostart_complete"), "no autostart completion log")
    end,
  },
}
