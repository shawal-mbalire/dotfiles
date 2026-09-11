-- Shared variable definitions for Hyprland Lua config
-- These are Lua tables that get passed to the cfg object

local M = {}

-- Programs
M.terminal = "kitty"
M.browser = "flatpak run app.zen_browser.zen"
M.note_taker = "obsidian"
M.code_editor = "code-insiders"
M.fileManager = "nautilus"
M.menu = 'fuzzel'
M.slack = "slack"
M.mainMod = "SUPER"
M.waybar_toggle = "~/.config/hypr/scripts/toggle_waybar.sh"
M.display_toggle = "~/.config/hypr/scripts/toggle_display.sh"

-- Colors and themes
M.active_border_color = { colors = { "rgba(89b4faff)", "rgba(89dcebee)" }, angle = 90 }
M.inactive_border_color = "rgba(45475aee)"
M.shadow_color = "rgba(1a1a1aee)"
M.blur_vibrancy = 0.1696

-- Sizes and gaps
M.gaps_in = 0
M.gaps_out = 0
M.border_size = 1
M.rounding = 3
M.shadow_range = 4
M.blur_size = 3

-- Monitors
M.primary_monitor = "eDP-1,1920x1200@60,0x0,1"
M.secondary_monitor = "HDMI-A-2,highres,0x0,1,mirror,eDP-1"

-- Input
M.kb_layout = "gb,ara,us"
M.mouse_sensitivity = 0
M.touchpad_natural_scroll = false
M.device_sensitivity = -0.5

-- Animation bezier curves
M.bezier_easeOutQuint = "0.23,1,0.32,1"
M.bezier_easeInOutCubic = "0.65,0.05,0.36,1"
M.bezier_linear = "0,0,1,1"
M.bezier_almostLinear = "0.5,0.5,0.75,1.0"
M.bezier_quick = "0.15,0,0.1,1"

-- Animation settings
M.animation_global = "1,10,default"
M.animation_border = "1,5.39,easeOutQuint"
M.animation_windows = "1,4.79,easeOutQuint"
M.animation_windowsIn = "1,4.1,easeOutQuint,popin 87%"
M.animation_windowsOut = "1,1.49,linear,popin 87%"
M.animation_fadeIn = "1,1.73,almostLinear"
M.animation_fadeOut = "1,1.46,almostLinear"
M.animation_fade = "1,3.03,quick"
M.animation_layers = "1,3.81,easeOutQuint"
M.animation_layersIn = "1,4,easeOutQuint,fade"
M.animation_layersOut = "1,1.5,linear,fade"
M.animation_fadeLayersIn = "1,1.79,almostLinear"
M.animation_fadeLayersOut = "1,1.39,almostLinear"
M.animation_workspaces = "1,1.94,almostLinear,fade"
M.animation_workspacesIn = "1,1.21,almostLinear,fade"
M.animation_workspacesOut = "1,1.94,almostLinear,fade"

-- Window rules
M.blurls = "waybar"

return M
