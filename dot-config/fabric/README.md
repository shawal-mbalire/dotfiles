# Fabric

A **Quickshell alternative in Python** — a Wayland desktop shell (top bar,
control center, app launcher, clipboard history, notification daemon, native
wallpaper renderer) built with **Hexagonal Architecture (Ports & Adapters)**.

This is a Python reimplementation of the sibling `../quickshell/` QML config,
porting the same feature set and the same architectural rules.

## Zero extra installations

Only two things are required:

- **Hyprland** — the compositor.
- **Fabric** — this shell.

Everything else is handled *natively inside Fabric*:

| Capability | Native mechanism | No shell-outs |
|---|---|---|
| Workspaces / focus / monitors | Hyprland's IPC Unix socket (`.socket.sock` / `.socket2.sock`) | no `hyprctl` |
| Wallpapers | Fabric paints them itself on a layer-shell `BACKGROUND` window per monitor | no `hyprpaper`, no `swww` |
| Battery, backlight | `/sys/class/power_supply`, `/sys/class/backlight` (+ optimistic writes) | no `acpi`, no `brightnessctl` |
| Wi-Fi, Bluetooth, notifications | D-Bus (NetworkManager, BlueZ, `org.freedesktop.Notifications` server) | no `nmcli`, no `bluetoothctl` |
| App launching | `.desktop` parsing + detached spawn | no `ls`, no shell scripts |
| Colour scheme | GSettings (Gio) | no `gsettings` CLI |
| Keybinds → shell | a control Unix socket | no IPC daemons |

The D-Bus protocol client and wire codec are implemented on the **standard
library** (`socket`, `struct`). Integrated daemons that are absent at runtime
degrade to honest "unavailable" adapters that log rather than fail.

## Architecture

```
       DRIVING SIDE                                    DRIVEN SIDE
  (trigger the domain)                            (the domain triggers)

  Hyprland keybind / IPC ─┐                 ┌─ Hyprland IPC, D-Bus, sysfs
  mouse / keyboard ───────┤                 ├─ GSettings, .desktop files
                          ▼                 │
  ┌─────────────────────────────────────────────────────────────┐
  │  adapters/driving      domain (pure)      adapters/driven    │
  │  GTK4 bar / menus  ──▶ ports · workflows ◀── native drivers  │
  │  control center        models · logic                       │
  │  wallpaper renderer    constants · errors                   │
  └─────────────────────────────────────────────────────────────┘
                          ▲
                   main.py (composition root)
             reads config → builds adapters → injects ports
```

Four root directories, exactly as the architecture requires:

| Root | Contents |
|------|----------|
| `domain/` | Pure logic: `models`, `logic`, `ports`, `workflows`, `constants`, `errors`, `result`. Imports nothing outward (enforced by `tests/guards/boundaries.py`). |
| `infra/` | `config` — the only place env vars are read. |
| `adapters/` | `driven/` (implement ports natively) and `driving/` (GTK4 views + a headless text presenter). |
| `tests/` | `unit/`, `contract/`, `fixtures/`, `guards/`. |

## Commands

```sh
just setup       # create the uv venv with dev tools
just verify      # ruff + mypy + architecture boundary guard + unit tests
just test-contract   # port-contract tests for every adapter
just check       # headless: wire everything, verify every port contract
just render      # headless smoke test: print the live bar model
just run         # launch the real GTK4 shell
```

## Runtime requirements (for `just run`)

- Python ≥ 3.11 (developed on 3.14)
- GTK4 + PyGObject + `gtk4-layer-shell` (the only system libraries, for rendering)
- Hyprland (for workspaces; the rest degrades without it)

## Layout at a glance

```
domain/workflows/presentation.py   pure bar/control-center model builders
domain/logic.py                    every pure transform (indicators, search,
                                   clipboard, notifications, duration, wallpapers)
domain/ports/                      one Protocol per capability
adapters/driven/hyprland/          native Hyprland IPC client + workspace adapter
adapters/driven/dbus/              stdlib D-Bus codec + transport
adapters/driven/sysfs/             battery + backlight
adapters/driven/network|bluetooth  NetworkManager / BlueZ via D-Bus
adapters/driven/notifications/     org.freedesktop.Notifications server
adapters/driven/desktop_entries/   .desktop parsing + launch
adapters/driven/wallpaper/         wallpaper store (the GTK side paints it)
adapters/driving/gtk/              layer-shell bar, overlays, wallpaper window
adapters/driving/text/             headless presenter
main.py                            composition root (--check/--render/run/ipc)
```