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
| Bar | `waybar` | Status bar |
| Launcher | `fuzzel` | Application launcher |
| Notifications | `swaync` | Notification daemon |
| File Manager | `nautilus` | GUI file manager |
| Git TUI | `lazygit` | Git interface |
| Git | `git` | Version control |
| GitHub CLI | `gh` | GitHub commands |

## Hyprland Ecosystem

| Package | Description |
|---------|-------------|
| `hyprlock` | Screen locker |
| `hyprpaper` | Wallpaper daemon |
| `hypridle` | Idle manager |
| `hyprpolkitagent` | Polkit authentication |
| `hyprsunset` | Blue light filter |

## System Utilities

| Package | Description |
|---------|-------------|
| `wl-clipboard` | Wayland clipboard (wl-paste, wl-copy) |
| `cliphist` | Clipboard history |
| `grimblast` | Screenshot tool |
| `brightnessctl` | Backlight control |
| `playerctl` | Media player control |
| `pavucontrol` | PulseAudio volume control |
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
  waybar fuzzel wl-clipboard cliphist grimblast \
  gammastep brightnessctl playerctl pavucontrol \
  network-manager-applet blueman swaync nautilus \
  hyprland hyprlock hypridle hyprpolkitagent hyprpaper \
  lua lua-devel luarocks go \
  jetbrains-mono-fonts

# Enable Hyprland COPR
sudo dnf copr enable lionheartp/Hyprland

# Enable SwayNC COPR
sudo dnf copr enable erikreider/SwayNotificationCenter
```

### Arch Linux
```sh
sudo pacman -S fish kitty tmux git lazygit \
  waybar fuzzel wl-clipboard cliphist grimblast \
  gammastep brightnessctl playerctl pavucontrol \
  network-manager-applet blueman swaync nautilus \
  hyprland hyprlock hypridle hyprpolkitagent hyprpaper \
  lua luarocks go \
  ttf-jetbrains-mono-nerd ttf-sono
```

### Debian/Ubuntu
```sh
sudo apt install fish kitty tmux git lazygit \
  waybar fuzzel wl-clipboard cliphist \
  brightnessctl playerctl pavucontrol \
  network-manager-gnome blueman swaync nautilus \
  fonts-jetbrains-mono

# Hyprland may need to be built from source
```

## Flatpaks

```sh
flatpak install flathub app.zen_browser.zen
flatpak install flathub com.slack.Slack
```

## Snaps

```sh
sudo snap install obsidian
sudo snap install code-insiders --classic
```
