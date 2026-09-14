# shore — a lean Quickshell shell

A single-process replacement for `waybar` + `swaync` + `swayosd`, built on
[Quickshell](https://quickshell.org) (QML/QtQuick). Target: Hyprland on Wayland.

Layered as a hexagon (ports and adapters):

```
shore/
├── shell.qml              # composition root: verifies adapters, wires the UI
├── domain/                # pure: no I/O
│   ├── Theme.qml          #   palette, fonts, metrics, glyphs
│   ├── Formatters.qml     #   pure presentation logic (percent, sorting, labels)
│   └── Constants.qml      #   named constants (thresholds, enum mirrors, steps)
├── infra/
│   └── Config.qml         # deployment config (paths, hardware window); only env reader
├── ports/
│   └── Verify.qml         # adapter contracts, asserted at startup
├── adapters/              # driven adapters: system access
│   ├── Backlight.qml      #   BrightnessPort (brightnessctl)
│   ├── Nightlight.qml     #   NightlightPort (gammastep via the waybar helper)
│   ├── Network.qml        #   NetworkPort (native Quickshell.Networking)
│   ├── Notifications.qml  #   NotificationPort (NotificationServer; replaces swaync)
│   ├── Polkit.qml         #   PolkitPort (auth agent; replaces hyprpolkitagent)
│   ├── Idle.qml           #   idle detection (replaces hypridle)
│   ├── Launcher.qml       #   DesktopEntries app catalog
│   └── Clipboard.qml      #   cliphist history
└── ui/                    # driving adapters: presentation
    ├── UiState.qml        #   panel/menu/OSD state
    ├── components/        #   bar widgets, menus, lock surface, wallpaper, reusable parts
    └── panels/            #   control center, menus, notifications, OSD, polkit, launcher, screenshot
```

Dependencies point inward: `ui → ports → domain`, and `adapters → domain`.
The composition root is the only place that knows every layer.


## Why one process

Everything lives in a single `qs` instance. Panels are wrapped in `LazyLoader`,
so hidden surfaces cost nothing and are destroyed when closed. Native services
(`Pipewire`, `UPower`, `Bluetooth`, `Mpris`, `SystemTray`, `Networking`) are
event-driven and in-process — no polling subprocess per widget. Only backlight
and night light shell out (there is no native service for them).

## Install

Quickshell is packaged on Fedora 44 (>= 0.3.0 is required for Hyprland's Lua
mode, which this config runs):

```sh
sudo dnf install quickshell
```

## Run

`shore` must be reachable at `~/.config/quickshell/shore`. Link it with stow
from the repo root (`stow --dotfiles .`), or directly:

```sh
ln -s ../dotfiles/dot-config/quickshell ~/.config/quickshell
```

Then:

```sh
qs -c shore          # run it
qs -c shore kill     # stop it
qs -c shore list     # check it is running
```

It is launched from Hyprland autostart (`infra/config.lua`, `M.autostart`).

### Migrating off the old daemons

Quickshell's `NotificationServer` and OSD are exclusive with the old ones.
Stop them before running (or just run `just migrate` in this directory):

```sh
pkill -x waybar; pkill -x swaync; pkill -x mako; pkill -x swayosd-server
pkill -x hypridle; pkill -x hyprpaper; pkill -x hyprpolkitagent
systemctl --user mask mako.service
```

Masking `mako.service` matters: `/usr/share/dbus-1/services/fr.emersion.mako.service`
declares `Name=org.freedesktop.Notifications`, so D-Bus would otherwise
auto-spawn mako whenever nothing owns the notification name (e.g. just before
Quickshell starts). Masked, activation fails instead and Quickshell keeps the
name.

Quickshell now owns: **bar, notifications, control center, OSD, polkit auth,
idle/lock, wallpaper, launcher (apps + clipboard) and region screenshots**. That
retires `waybar`, `swaync`, `mako`, `swayosd-server`, `hyprpolkitagent`,
`hypridle`, `hyprpaper`, `fuzzel` (for the menu/clipboard) and `grimblast`.
Hyprland's autostart and `HYPR_WALLPAPER_DAEMON` (default `0`) reflect this.
`gammastep`, `cliphist`/`wl-clipboard` and `brightnessctl` remain as helpers.

## Wiring

Hyprland binds call Quickshell over IPC (`qs -c shore ipc call quickshell <fn>`), see
`dot-config/hypr/infra/config.lua`:

| Binding | Command |
|---|---|
| `SUPER + B` | `qs -c shore ipc call quickshell toggleBar` |
| `SUPER + N` | `qs -c shore ipc call quickshell toggleControlCenter` |
| `SUPER + SHIFT + N` | `qs -c shore ipc call quickshell clearNotifications` |
| `SUPER + P` | `qs -c shore ipc call quickshell openLauncher apps` |
| `SUPER + V` | `qs -c shore ipc call quickshell openLauncher clipboard` |
| `SUPER + L` | `qs -c shore ipc call quickshell lock` |
| `SUPER + W` | `qs -c shore ipc call quickshell nextWallpaper` |
| Print | `qs -c shore ipc call quickshell screenshot` |
| brightness keys | `qs -c shore ipc call quickshell brightnessStep up\|down` (falls back to `brightnessctl`) |

Available IPC functions: `toggleBar`, `toggleControlCenter`, `closePanels`,
`toggleDnd`, `clearNotifications`, `brightnessStep <up|down>`,
`openMenu <bluetooth|wifi|audio|power|display>`, `openLauncher <apps|clipboard>`,
`lock`, `screenshot`, `nextWallpaper`.

## Session surfaces

- **Lock** (`ui/components/LockSurface.qml` + `LockContext.qml`): `WlSessionLock`
  surface per monitor, PAM auth via `Quickshell.Services.Pam` with a local
  `pam/password.conf`. The background is the current wallpaper blurred
  (`MultiEffect`), with a large clock. Idle locks it after
  `Constants.idleLockSeconds` (via `adapters/Idle.qml`, replacing hypridle) and
  suspends after `idleSuspendSeconds`.
- **Wallpaper** (`ui/components/WallpaperSurface.qml`): rendered on the
  background layer per monitor. It cycles through every image in
  `Config.wallpaperDir` (`~/Pictures/Wallpapers`); `SUPER+W` /
  `nextWallpaper` advances it (falls back to `Config.wallpaper` when the folder
  is empty). Replaces hyprpaper.
- **Dynamic theming**: `adapters/WallpaperColors.qml` runs `ColorQuantizer` on
  the current wallpaper and exposes a vivid accent; selection/focus highlights
  across the bar, menus, launcher, OSD, polkit prompt and lock use it, so
  changing the wallpaper retints the shell.
- **Launcher** (`ui/panels/Launcher.qml`): applications (`DesktopEntries`) and
  clipboard history (`adapters/Clipboard.qml`, cliphist) in one searchable
  overlay; replaces fuzzel for the menu and clipboard.
- **Screenshot** (`ui/panels/ScreenshotOverlay.qml`): `ScreencopyView` region
  capture saved to `~/Pictures/Screenshots` and copied to the clipboard;
  replaces grimblast.

## Bar interactions

Pills open **in-shell submenus** (`ui/panels/MenuPopup.qml`); nothing shells out
to fuzzel menus. Menus share a header/section hierarchy (`MenuTitle`,
`SectionLabel`).

| Pill | left | right | scroll |
|---|---|---|---|
| Workspaces | activate | — | — |
| Clock | toggle time/date | — | — |
| Notifications | control center | DND | clear all |
| Night light | toggle | — | — |
| Network | Wi-Fi menu | control center | — |
| Power profile | power menu | power menu | — |
| Audio | output/input menu | mute | volume |
| Backlight | control center | control center | step (raw 30–30000 ↔ 0–100%) |
| Battery | — | — | — |
| Bluetooth | device manager | device manager | — |
| Tray | activate | menu | scroll |

The Bluetooth menu lists devices with Connect/Disconnect, Pair and Forget, plus
a scan button. Power is a switch **inside the menu**, so it can't be toggled by
a stray bar click.

The audio menu manages **outputs and inputs** (select default, per-device
volume + mute) via Pipewire. The control center shows a **Displays** tile when
more than one monitor is attached, opening a monitor menu (disable/enable,
mirror/extend).

The Wi-Fi menu (left-click the network pill) toggles the radio, scans, lists
networks by signal, and connects — prompting for a password inline instead of
opening an external window. Right-click a known network to forget it.

The night light (gammastep) is owned by the bar pill, which drives gammastep
directly; the standalone `gammastep-indicator` tray app is no longer started.

## Reused helper

`adapters/Nightlight.qml` delegates to the existing Python hexagon
(`~/.config/waybar/scripts/main.py nightlight`). Everything else is native.

## Lint

`qmllint` ships with `qt6-qtdeclarative-devel`:

```sh
just lint
# or:
qmllint -I /usr/lib64/qt6/qml shell.qml domain/*.qml infra/*.qml ports/*.qml \
        adapters/*.qml ui/*.qml ui/components/*.qml ui/panels/*.qml
```
