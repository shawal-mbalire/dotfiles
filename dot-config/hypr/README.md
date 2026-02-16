# Hyprland Config (12-Factor Style)

This Hyprland config is structured like a 12-factor app for portability and maintainability. The base `hyprland.conf` defines variables and sources modular config files.

## Setup
1. Install dependencies from `dependencies.txt` (includes hyprpolkitagent for polkit authentication).
2. Ensure Hyprland is configured to use `~/.config/hypr/hyprland.conf`.
3. Check `portability.md` for distro/hardware-specific tweaks.

## Structure
- `hyprland.conf`: Main config with variable definitions and sources.
- `monitors.conf`: Monitor settings.
- `autostart.conf`: Startup processes.
- `env.conf`: Environment variables.
- `look.conf`: Appearance (general, decoration, animations).
- `input.conf`: Input devices.
- `keybindings.conf`: Key bindings.
- `windows.conf`: Window and workspace rules.
- `hyprlock.conf`: Lock screen.
- `hyprpaper.conf`: Wallpaper.
- `hyprland-laptop.conf`: Example variant for laptop environment.
- `scripts/toggle_waybar.sh`: Script to toggle waybar on/off (used in keybindings).
- `portability.md`: Guide for adapting to different distros/hardware.

## Workflow
### Build (Edit)
- Edit variables in `hyprland.conf` (e.g., change `$terminal`).
- Modify sourced files as needed.

### Release (Validate)
- Run: `hyprland --config hyprland.conf --verify-config`

### Deploy (Apply)
- Restart Hyprland: `hyprctl reload` (or logout/login).

### Environments
- For different setups (e.g., laptop), copy `hyprland.conf` to `hyprland-laptop.conf`, edit vars/sources, and point Hyprland to it (e.g., via symlink or config path).

## Notes
- All changes are git-tracked for versioning.
- For portability, use relative paths or env vars in variables.
- The waybar toggle script is included for the binding to work.