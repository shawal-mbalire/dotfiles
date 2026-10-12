---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--

local shell = require("lua.env")

hl.on("hyprland.start", function()
	-- tmux.service starts before Hyprland, so its panes lack the Hyprland socket env;
	-- a qs started from tmux then never sees workspace events.
	hl.exec_cmd("sh -c 'tmux set-environment -g HYPRLAND_INSTANCE_SIGNATURE \"$HYPRLAND_INSTANCE_SIGNATURE\"; tmux set-environment -g WAYLAND_DISPLAY \"$WAYLAND_DISPLAY\"'")
	-- Restart qs if it exits, so the keybinds (qs ipc call …) keep working.
	hl.exec_cmd("sh -c 'while true; do qs; sleep 1; done'")
	hl.exec_cmd("gammastep -m wayland -O " .. shell.colorTemperature)
end)
