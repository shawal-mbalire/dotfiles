-- Keybindings configuration
local v = require("modules.variables")

local function bind(mods, key, dispatcher, opts)
  if mods and mods ~= "" then
    hl.bind(mods .. " + " .. key, dispatcher, opts)
  else
    hl.bind(key, dispatcher, opts)
  end
end

local function exec_cmd(cmd)
  return hl.dsp.exec_cmd(cmd)
end

-- Application launchers
bind(v.mainMod, "SHIFT + RETURN", exec_cmd(v.terminal))
bind(v.mainMod, "SHIFT + O", exec_cmd(v.note_taker))
bind(v.mainMod, "SHIFT + Z", exec_cmd(v.browser))
bind(v.mainMod, "SHIFT + V", exec_cmd("pavucontrol"))
bind(v.mainMod, "SHIFT + I", exec_cmd("code-insiders"))
bind(v.mainMod, "ALT + F", hl.dsp.window.float())
bind(v.mainMod, "E", exec_cmd(v.fileManager))
bind(v.mainMod, "Q", hl.dsp.window.close())
bind(v.mainMod, "P", exec_cmd(v.menu))
bind(v.mainMod, "V", exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))
bind(v.mainMod, "R", hl.dsp.window.pseudo())
bind(v.mainMod, "B", exec_cmd(v.waybar_toggle))
bind(v.mainMod, "M", exec_cmd(v.display_toggle))

-- Notifications (swaync)
bind(v.mainMod, "N", exec_cmd("swaync-client -t -sw"))
bind(v.mainMod, "SHIFT + N", exec_cmd("swaync-client -d -sw"))

-- Focus movement (vim-style)
bind(v.mainMod, "H", hl.dsp.focus({ direction = "l" }))
bind(v.mainMod, "J", hl.dsp.focus({ direction = "d" }))
bind(v.mainMod, "K", hl.dsp.focus({ direction = "u" }))
bind(v.mainMod, "L", hl.dsp.focus({ direction = "r" }))

-- Window movement
bind(v.mainMod, "SHIFT + H", hl.dsp.window.move({ direction = "l" }))
bind(v.mainMod, "SHIFT + J", hl.dsp.window.move({ direction = "d" }))
bind(v.mainMod, "SHIFT + K", hl.dsp.window.move({ direction = "u" }))
bind(v.mainMod, "SHIFT + L", hl.dsp.window.move({ direction = "r" }))

-- Resize windows
bind(v.mainMod, "CTRL + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
bind(v.mainMod, "CTRL + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
bind(v.mainMod, "CTRL + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
bind(v.mainMod, "CTRL + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

-- Move workspace to another monitor
bind(v.mainMod, "ALT + U", hl.dsp.workspace.move({ monitor = "l" }))
bind(v.mainMod, "ALT + J", hl.dsp.workspace.move({ monitor = "r" }))
bind(v.mainMod, "ALT + H", hl.dsp.workspace.move({ monitor = "u" }))
bind(v.mainMod, "ALT + G", hl.dsp.workspace.move({ monitor = "d" }))

-- Switch workspaces with mainMod + [0-9]
for i = 1, 9 do
  bind(v.mainMod, tostring(i), hl.dsp.focus({ workspace = tostring(i) }))
end
bind(v.mainMod, "0", hl.dsp.focus({ workspace = "10" }))

-- Move active window to workspace
for i = 1, 9 do
  bind(v.mainMod, "SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end
bind(v.mainMod, "SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

-- Special workspace (scratchpad)
bind(v.mainMod, "S", hl.dsp.workspace.toggle_special("magic"))
bind(v.mainMod, "SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
bind(v.mainMod, "mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(v.mainMod, "mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse
bind(v.mainMod, "mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(v.mainMod, "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume (laptop multimedia keys)
bind("", "XF86AudioRaiseVolume", exec_cmd("~/.config/waybar/scripts/volume-control.sh up"), { repeating = true, locked = true })
bind("", "XF86AudioLowerVolume", exec_cmd("~/.config/waybar/scripts/volume-control.sh down"), { repeating = true, locked = true })
bind("", "XF86AudioMute", exec_cmd("~/.config/waybar/scripts/volume-control.sh mute"), { locked = true })
bind("", "XF86AudioMicMute", exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Brightness
bind("", "XF86MonBrightnessUp", exec_cmd("brightnessctl s 10%+"), { repeating = true, locked = true })
bind("", "XF86MonBrightnessDown", exec_cmd("brightnessctl s 10%-"), { repeating = true, locked = true })

-- Playerctl
bind("", "XF86AudioNext", exec_cmd("playerctl next"), { locked = true })
bind("", "XF86AudioPause", exec_cmd("playerctl play-pause"), { locked = true })
bind("", "XF86AudioPlay", exec_cmd("playerctl play-pause"), { locked = true })
bind("", "XF86AudioPrev", exec_cmd("playerctl previous"), { locked = true })

-- Screenshots
bind("", "Print", exec_cmd("grimblast --freeze copysave area"))
bind("SUPER", "ALT + 4", exec_cmd("grimblast --freeze copysave area"))