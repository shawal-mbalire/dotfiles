-- Infra config: env vars read here, nowhere else.
-- The composition root reads this table and injects it into workflows.

local M = {}

M.log_level = os.getenv("HYPR_LOG_LEVEL") or "info"

M.profile = os.getenv("HYPR_PROFILE") or "desktop"
M.laptop = M.profile == "laptop"
M.mainMod = "SUPER"

M.apps = {
  terminal       = os.getenv("HYPR_TERMINAL") or "kitty",
  browser        = os.getenv("HYPR_BROWSER") or "flatpak run app.zen_browser.zen",
  file_manager   = os.getenv("HYPR_FILE_MANAGER") or "nautilus",
  menu           = os.getenv("HYPR_MENU") or "qs ipc call quickshell openLauncher apps",
  note_taker     = os.getenv("HYPR_NOTE_TAKER") or "obsidian",
  editor         = os.getenv("HYPR_EDITOR") or "code-insiders",
  audio          = os.getenv("HYPR_AUDIO") or "pavucontrol",
  bar_toggle     = os.getenv("HYPR_BAR_TOGGLE") or "qs ipc call quickshell toggleBar",
  display_toggle = os.getenv("HYPR_DISPLAY_TOGGLE") or "~/.config/hypr/scripts/toggle_display.py",
}

-- Commands invoked by binds and autostart (single source of truth).
M.commands = {
  volume_up     = os.getenv("HYPR_VOLUME_UP") or "~/.config/waybar/scripts/main.py audio volume up",
  volume_down   = os.getenv("HYPR_VOLUME_DOWN") or "~/.config/waybar/scripts/main.py audio volume down",
  volume_mute   = os.getenv("HYPR_VOLUME_MUTE") or "~/.config/waybar/scripts/main.py audio volume mute",
  mic_mute      = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
  brightness_up = os.getenv("HYPR_BRIGHTNESS_UP") or "qs ipc call quickshell brightnessStep up || brightnessctl s 10%+",
  brightness_down = os.getenv("HYPR_BRIGHTNESS_DOWN") or "qs ipc call quickshell brightnessStep down || brightnessctl s 10%-",
  media_next    = "playerctl next",
  media_play    = "playerctl play-pause",
  media_prev    = "playerctl previous",
  clipboard     = os.getenv("HYPR_CLIPBOARD") or "qs ipc call quickshell openLauncher clipboard",
  notify_toggle = os.getenv("HYPR_NOTIFY_TOGGLE") or "qs ipc call quickshell toggleControlCenter",
  notify_dismiss = os.getenv("HYPR_NOTIFY_DISMISS") or "qs ipc call quickshell clearNotifications",
  screenshot    = os.getenv("HYPR_SCREENSHOT") or "qs ipc call quickshell screenshot",
  lock          = os.getenv("HYPR_LOCK") or "qs ipc call quickshell lock",
  wallpaper_next = os.getenv("HYPR_WALLPAPER_NEXT") or "qs ipc call quickshell nextWallpaper",
  frost_toggle   = "test -f /tmp/hypr_frost && (rm -f /tmp/hypr_frost; hyprctl keyword windowrulev2 \"opacity 1.0 1.0, class:kitty\") || (touch /tmp/hypr_frost; hyprctl keyword windowrulev2 \"opacity 0.85 0.85, class:kitty\")",
}

M.displays = {
  { output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1 },
}

if not M.laptop then
  table.insert(M.displays, {
    output = "HDMI-A-2", mode = "highres", position = "0x0", scale = 1, mirror = "eDP-1",
  })
end

M.input = {
  kb_layout   = M.laptop and "gb,ara" or "gb,ara,us",
  kb_variant  = "",
  kb_model    = "",
  kb_options  = "caps:swapescape, grp:win_space_toggle",
  kb_rules    = "",
  follow_mouse = 1,
  sensitivity = 0,
  touchpad    = { natural_scroll = false },
  mouse       = { name = "epic-mouse-v1", sensitivity = -0.5 },
}

M.visual = {
  gaps_in     = M.laptop and 4 or 0,
  gaps_out    = M.laptop and 5 or 0,
  border_size = 0,
  rounding    = M.laptop and 5 or 3,
  rounding_power = 2,
  gradient_angle = 90,
  active_opacity = 1.0,
  inactive_opacity = 1.0,
  shadow_enabled = false,
  shadow_range = 4,
  shadow_render_power = 3,
  blur_enabled = false,
  blur_size = 5,
  blur_passes = 4,
  blur_vibrancy = 0.1696,
  resize_on_border = false,
  allow_tearing = false,
  force_default_wallpaper = 0,
  disable_hyprland_logo = true,
}

M.colors = {
  active   = M.laptop and { hex = "33ccff", alpha = 255 } or { hex = "89b4fa", alpha = 255 },
  inactive = M.laptop and { hex = "595959", alpha = 170 } or { hex = "45475a", alpha = 238 },
  shadow   = { hex = "1a1a1a", alpha = 238 },
}

M.env = {
  HYPRCURSOR_THEME = "Breeze",
  XCURSOR_THEME    = "Breeze",
  XCURSOR_SIZE     = "24",
  HYPRCURSOR_SIZE  = "24",
}

-- Wallpaper: Quickshell renders the wallpaper itself, so the hyprpaper daemon
-- is disabled by default. Set HYPR_WALLPAPER_DAEMON=1 to fall back to hyprpaper
-- (the conf is still rendered below).
local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
M.wallpaper = {
  daemon = (os.getenv("HYPR_WALLPAPER_DAEMON") or "0") ~= "0",
  conf_path = os.getenv("HYPR_WALLPAPER_CONF") or (runtime_dir .. "/hyprpaper.conf"),
  wallpapers = {
    {
      path = os.getenv("HYPR_WALLPAPER") or ((os.getenv("HOME") or "") .. "/wallpaper.jpg"),
      fit_mode = "cover",
      monitors = {},
    },
  },
}

M.autostart = {
  "nm-applet",
  "gammastep -O 16000",
  "wl-paste --watch cliphist store",
  "/usr/libexec/hyprpolkitagent",
  -- Recover Bluetooth if rfkill soft-block was persisted from a prior session.
  "rfkill unblock bluetooth",
  -- Quickshell replaces waybar + swaync + swayosd-server:
  -- one process owns the bar, notifications, control center and OSD.
  -- Stop the old daemons before enabling this.
  "qs",
}

return M
