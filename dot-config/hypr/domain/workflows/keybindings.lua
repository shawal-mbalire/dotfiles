-- Workflow: all key and mouse bindings.

local models = require("domain.models")
local constants = require("domain.constants")

local function bind(mods, key, action, opts)
  return models.Bind.new(mods, key, action, opts)
end

local function build(config)
  local mainMod = config.mainMod
  local apps = config.apps
  local cmd = config.commands

  local list = {
    -- applications
    bind(mainMod, "SHIFT + RETURN", models.Bind.exec(apps.terminal)),
    bind(mainMod, "SHIFT + O", models.Bind.exec(apps.note_taker)),
    bind(mainMod, "SHIFT + Z", models.Bind.exec(apps.browser)),
    bind(mainMod, "SHIFT + V", models.Bind.exec(apps.audio)),
    bind(mainMod, "SHIFT + I", models.Bind.exec(apps.editor)),
    bind(mainMod, "E", models.Bind.exec(apps.file_manager)),
    bind(mainMod, "P", models.Bind.exec(apps.menu)),
    bind(mainMod, "B", models.Bind.exec(apps.waybar_toggle)),
    bind(mainMod, "M", models.Bind.exec(apps.display_toggle)),
    bind(mainMod, "V", models.Bind.exec(cmd.clipboard)),
    bind(mainMod, "N", models.Bind.exec(cmd.notify_toggle)),
    bind(mainMod, "SHIFT + N", models.Bind.exec(cmd.notify_dismiss)),

    -- window management
    bind(mainMod, "ALT + F", models.Bind.window("float")),
    bind(mainMod, "Q", models.Bind.window("close")),
    bind(mainMod, "R", models.Bind.window("pseudo")),

    -- focus (vim)
    bind(mainMod, "H", models.Bind.focus({ direction = "l" })),
    bind(mainMod, "J", models.Bind.focus({ direction = "d" })),
    bind(mainMod, "K", models.Bind.focus({ direction = "u" })),
    bind(mainMod, "L", models.Bind.focus({ direction = "r" })),

    -- move window (vim)
    bind(mainMod, "SHIFT + H", models.Bind.window("move", { direction = "l" })),
    bind(mainMod, "SHIFT + J", models.Bind.window("move", { direction = "d" })),
    bind(mainMod, "SHIFT + K", models.Bind.window("move", { direction = "u" })),
    bind(mainMod, "SHIFT + L", models.Bind.window("move", { direction = "r" })),

    -- resize
    bind(mainMod, "CTRL + H", models.Bind.window("resize", { x = -constants.RESIZE_STEP, y = 0, relative = true })),
    bind(mainMod, "CTRL + L", models.Bind.window("resize", { x = constants.RESIZE_STEP, y = 0, relative = true })),
    bind(mainMod, "CTRL + K", models.Bind.window("resize", { x = 0, y = -constants.RESIZE_STEP, relative = true })),
    bind(mainMod, "CTRL + J", models.Bind.window("resize", { x = 0, y = constants.RESIZE_STEP, relative = true })),

    -- move workspace to monitor
    bind(mainMod, "ALT + U", models.Bind.workspace({ move = true, monitor = "l" })),
    bind(mainMod, "ALT + J", models.Bind.workspace({ move = true, monitor = "r" })),
    bind(mainMod, "ALT + H", models.Bind.workspace({ move = true, monitor = "u" })),
    bind(mainMod, "ALT + G", models.Bind.workspace({ move = true, monitor = "d" })),

    -- special workspace
    bind(mainMod, "S", models.Bind.workspace({ toggle_special = true, name = constants.SPECIAL_WS })),
    bind(mainMod, "SHIFT + S", models.Bind.window("move", { workspace = "special:" .. constants.SPECIAL_WS })),

    -- mouse
    bind(mainMod, "mouse_down", models.Bind.focus({ workspace = "e+1" })),
    bind(mainMod, "mouse_up", models.Bind.focus({ workspace = "e-1" })),
    bind(mainMod, constants.MOUSE.LEFT, models.Bind.window("drag"), { mouse = true }),
    bind(mainMod, constants.MOUSE.RIGHT, models.Bind.window("resize"), { mouse = true }),

    -- media and hardware keys
    bind("", "XF86AudioRaiseVolume", models.Bind.exec(cmd.volume_up), { repeating = true, locked = true }),
    bind("", "XF86AudioLowerVolume", models.Bind.exec(cmd.volume_down), { repeating = true, locked = true }),
    bind("", "XF86AudioMute", models.Bind.exec(cmd.volume_mute), { locked = true }),
    bind("", "XF86AudioMicMute", models.Bind.exec(cmd.mic_mute), { locked = true }),
    bind("", "XF86MonBrightnessUp", models.Bind.exec(cmd.brightness_up), { repeating = true, locked = true }),
    bind("", "XF86MonBrightnessDown", models.Bind.exec(cmd.brightness_down), { repeating = true, locked = true }),
    bind("", "XF86AudioNext", models.Bind.exec(cmd.media_next), { locked = true }),
    bind("", "XF86AudioPause", models.Bind.exec(cmd.media_play), { locked = true }),
    bind("", "XF86AudioPlay", models.Bind.exec(cmd.media_play), { locked = true }),
    bind("", "XF86AudioPrev", models.Bind.exec(cmd.media_prev), { locked = true }),

    -- screenshots
    bind("", "Print", models.Bind.exec(cmd.screenshot)),
    bind("SUPER", "ALT + 4", models.Bind.exec(cmd.screenshot)),
  }

  -- workspaces 1..MAX_WS (key 10 maps to "0")
  for i = 1, constants.MAX_WS do
    local key = tostring(i % constants.MAX_WS)
    table.insert(list, bind(mainMod, key, models.Bind.focus({ workspace = tostring(i) })))
    table.insert(list, bind(mainMod, "SHIFT + " .. key, models.Bind.window("move", { workspace = tostring(i) })))
  end

  return list
end

return function(deps)
  local list = build(deps.config)
  deps.binding:register_binds(list)
  deps.logger:info("keybindings_registered", { count = #list })
end
