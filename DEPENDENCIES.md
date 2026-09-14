# Dependencies

Major packages required for this dotfiles configuration.

## Core Components

| Category | Package | Description |
|----------|---------|-------------|
| Shell | `fish` | Default shell |
| Terminal | `kitty` | Terminal emulator |
| Multiplexer | `tmux` | Terminal multiplexer |
| Editor | `nvim` | Neovim (configured via LazyVim) |
| Compositor | `hyprland` | Wayland compositor |
| Login | `greetd` | Display manager (replaces gdm; see `dot-config/quickshell/greet`) |
| Login | `cage` | Kiosk compositor that hosts the Quickshell login greeter |
| Shell | `quickshell` | Bar + notifications + control center + OSD + lock + wallpaper + idle + polkit (replaces waybar/swaync/swayosd/hyprlock/hyprpaper/hypridle/hyprpolkitagent/grimblast/fuzzel) |
| File Manager | `nautilus` | GUI file manager |
| Git TUI | `lazygit` | Git interface |
| Git | `git` | Version control |
| GitHub CLI | `gh` | GitHub commands |

## System Utilities

| Package | Description |
|---------|-------------|
| `wl-clipboard` | Wayland clipboard (wl-paste, wl-copy) |
| `cliphist` | Clipboard history |
| `brightnessctl` | Backlight control |
| `playerctl` | Media player control |
| `easyeffects` | Audio filter/effects tweaker (PipeWire), launched from the audio menu |
| `network-manager-applet` | Network tray (nm-applet) |
| `blueman` | Bluetooth manager |

## Fonts

| Package | Description |
|---------|-------------|
| `jetbrains-mono-nerd` | Primary monospace font |
| `fonts-sono` | Sans font |

## Dev Dependencies

| Package | Description |
|---------|-------------|
| `lua` | Lua language |
| `lua-devel` | Lua development headers |
| `luarocks` | Lua package manager |
| `go` | Go language |

---

## Installation by Distro

### Fedora
```sh
sudo dnf install fish kitty tmux git lazygit \
  quickshell wl-clipboard cliphist easyeffects \
  gammastep brightnessctl playerctl \
  network-manager-applet blueman nautilus \
  hyprland greetd cage fprintd-pam \
  lua lua-devel luarocks go \
  jetbrains-mono-fonts

# Enable Hyprland COPR (provides quickshell and hyprland on Fedora)
sudo dnf copr enable lionheartp/Hyprland
```

### Arch Linux
```sh
sudo pacman -S fish kitty tmux git lazygit \
  quickshell wl-clipboard cliphist easyeffects \
  gammastep brightnessctl playerctl \
  network-manager-applet blueman nautilus \
  hyprland greetd cage fprintd \
  lua luarocks go \
  ttf-jetbrains-mono-nerd ttf-sono
```

### Debian/Ubuntu
```sh
sudo apt install fish kitty tmux git lazygit \
  wl-clipboard cliphist easyeffects \
  brightnessctl playerctl \
  network-manager-gnome blueman nautilus \
  fonts-jetbrains-mono

# quickshell, hyprland and greetd may need to be built from source
```

## Flatpaks

```sh
flatpak install flathub app.zen_browser.zen
flatpak install flathub com.slack.Slack
```

## Snaps

User-installed snaps (both classic confinement):

```sh
sudo snap install android-studio --classic
sudo snap install code-insiders --classic
```
