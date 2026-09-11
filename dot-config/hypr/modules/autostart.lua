-- Autostart applications and services
hl.on("hyprland.start", function()
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("gammastep-indicator")

  hl.exec_cmd("swaync")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("wl-paste --watch cliphist store")
  hl.exec_cmd("gammastep -O 16000")
  hl.exec_cmd("swayosd-server")

  -- Hypr packages
  hl.exec_cmd("hypridle")
  hl.exec_cmd("hyprsunset")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("hyprpaper -c ~/.config/hypr/modules/hyprpaper.conf")
end)