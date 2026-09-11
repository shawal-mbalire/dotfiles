# Hyprland Config (12-Factor Style)

This Hyprland config is structured like a 12-factor app for portability and maintainability. The base `hyprland.lua` defines variables and requires modular config files.

## Setup
1. Install dependencies from `dependencies.txt` (includes hyprpolkitagent for polkit authentication).
2. Ensure Hyprland is configured to use `~/.config/hypr/hyprland.lua`.
3. Check `portability.md` for distro/hardware-specific tweaks.

## Structure
- `hyprland.lua`: Main config entry point (desktop variant).
- `hyprland-laptop.lua`: Laptop variant with different defaults.
- `modules/variables.lua`: Shared variable definitions.
- `modules/displays.lua`: Monitor settings (desktop).
- `modules/displays-laptop.lua`: Monitor settings (laptop).
- `modules/autostart.lua`: Startup processes.
- `modules/env.lua`: Environment variables.
- `modules/look.lua`: Appearance (general, decoration, animations).
- `modules/input.lua`: Input devices.
- `modules/keybindings.lua`: Key bindings.
- `modules/windows.lua`: Window and workspace rules.
- `hyprlock.conf`: Lock screen.
- `hyprpaper.conf`: Wallpaper.
- `hypridle.conf`: Idle management.
- `hyprsunset.conf`: Night light.
- `scripts/toggle_waybar.sh`: Script to toggle waybar on/off.
- `scripts/toggle_display.sh`: Script to toggle mirror/extend display mode.
- `scripts/battery-notify.sh`: Battery level notifications via swaync.

## Workflow
### Build (Edit)
- Edit variables in `modules/variables.lua` (e.g., change `M.terminal`).
- Modify module files as needed.

### Release (Validate)
- Run: `hyprctl reload`

### Environments
- For different setups (e.g., laptop), point Hyprland to `hyprland-laptop.lua` (e.g., via symlink or config path).