# Waybar Configuration

Catppuccin Mocha themed waybar with pill-style modules and 1px borders.

## Install Dependencies (Fedora)

```bash
sudo dnf install waybar jetbrains-mono-fonts sono-fonts pavucontrol brightnessctl
```

### Optional Dependencies

- **Screenshots**: `hyprshot`
- **Terminal**: `foot`
- **Network**: `network-manager-applet` (for `nm-connection-editor`)
- **Power Management**: `power-profiles-daemon`

## Reload Waybar

```bash
killall waybar && waybar &
```

Or use the Hyprland keybind (usually `Super + Shift + R`).
