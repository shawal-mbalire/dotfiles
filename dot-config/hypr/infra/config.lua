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
  menu           = os.getenv("HYPR_MENU") or "fuzzel",
  note_taker     = os.getenv("HYPR_NOTE_TAKER") or "obsidian",
  editor         = os.getenv("HYPR_EDITOR") or "code-insiders",
  audio          = os.getenv("HYPR_AUDIO") or "pavucontrol",
  waybar_toggle  = os.getenv("HYPR_WAYBAR_TOGGLE") or "pkill -x waybar || (waybar &)",
  display_toggle = os.getenv("HYPR_DISPLAY_TOGGLE") or "~/.config/hypr/scripts/toggle_display.py",
}

-- Commands invoked by binds and autostart (single source of truth).
M.commands = {
  volume_up     = os.getenv("HYPR_VOLUME_UP") or "~/.config/waybar/scripts/main.py audio volume up",
  volume_down   = os.getenv("HYPR_VOLUME_DOWN") or "~/.config/waybar/scripts/main.py audio volume down",
  volume_mute   = os.getenv("HYPR_VOLUME_MUTE") or "~/.config/waybar/scripts/main.py audio volume mute",
  mic_mute      = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
  brightness_up = os.getenv("HYPR_BRIGHTNESS_UP") or "brightnessctl s 10%+",
  brightness_down = os.getenv("HYPR_BRIGHTNESS_DOWN") or "brightnessctl s 10%-",
  media_next    = "playerctl next",
  media_play    = "playerctl play-pause",
  media_prev    = "playerctl previous",
  clipboard     = "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy",
  notify_toggle = "swaync-client -t -sw",
  notify_dismiss = "swaync-client -d -sw",
  screenshot    = "grimblast --freeze copysave area",
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
  border_size = 1,
  rounding    = M.laptop and 5 or 3,
  rounding_power = 2,
  gradient_angle = 90,
  active_opacity = 1.0,
  inactive_opacity = 1.0,
  shadow_enabled = true,
  shadow_range = 4,
  shadow_render_power = 3,
  blur_enabled = true,
  blur_size = 3,
  blur_passes = 1,
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

M.autostart = {
  "nm-applet",
  "gammastep-indicator",
  "swaync",
  "systemctl --user start hyprpolkitagent",
  "wl-paste --watch cliphist store",
  "swayosd-server",
  "hypridle",
}

return M
