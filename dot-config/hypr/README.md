# Hyprland Config (Hexagonal Architecture)

Domain owns the config logic. Adapters translate to the `hl.*` API. Infra reads
env vars. The composition root wires everything together.

## Structure

```
├── domain/                     # Pure application logic (no hl.*, no env)
│   ├── models.lua              # Color, Bezier, Anim, Bind, Display, LayerRule,
│   │                           #   VisualSettings, InputSettings, Device, Wallpaper
│   ├── constants.lua           # Static rules: RESIZE_STEP, MAX_WS, MOUSE, curves,
│   │                           #   layers, EVENTS, ACTION vocabulary
│   ├── ports/                  # Small port contracts + verify.lua conformance check
│   │   ├── monitor.lua  environment.lua  input.lua  binding.lua
│   │   ├── command.lua  visual.lua  layer.lua  runtime.lua
│   │   └── wallpaper.lua  logger.lua  time.lua  lifetime.lua
│   └── workflows/              # Orchestration, dependencies injected as `deps`
│       ├── displays.lua  env.lua  look.lua  wallpaper.lua  input.lua
│       └── keybindings.lua  windows.lua  autostart.lua  wallpaper_daemon.lua
├── adapters/                   # Plumbing: implement ports against external systems
│   ├── hyprland_adapter.lua    # Implements the Hyprland ports via hl.*
│   ├── hyprland_mappings.lua   # Pure DTO mapping (Display -> rule, action -> dispatcher)
│   ├── hyprpaper_adapter.lua   # Implements WallpaperPort: writes conf + owns daemon
│   ├── hyprpaper_mappings.lua  # Pure mapping (Wallpaper model -> conf text/cmd)
│   ├── console_logger.lua      # LoggerPort
│   ├── system_time.lua         # TimePort
│   └── process_lifetime.lua    # LifetimePort
├── infra/
│   └── config.lua              # Env vars read HERE only
├── tests/
│   ├── fixtures/               # fakes.lua (in-memory ports), fake_hl.lua
│   ├── unit/                   # models, constants, mappings, adapter, workflows
│   └── integration/            # loads the real composition root against fake hl
├── scripts/                    # Python hexagon (helper CLIs)
│   ├── main.py                 # Composition root + CLI (display-toggle, battery-notify)
│   ├── toggle_display.py       # Entry shim -> main.py display-toggle (keybinding path)
│   ├── battery-notify.py       # Entry shim -> main.py battery-notify
│   ├── dev.py                  # Devtool: logs / watch / e2e / lint / typecheck / clean
│   ├── domain/                 # models, constants, errors, ports/, workflows/
│   ├── adapters/               # hyprctl, sysfs, notify-send, markers, cross-cutting
│   ├── infra/                  # config.py (env), paths.py (XDG)
│   └── tests/                  # fixtures/, unit/, integration/ (pytest)
├── hyprland.lua                # Composition root (entry point)
├── justfile                    # run / test / lint / typecheck / check
└── README.md
```

## How it works

- **infra/config.lua** reads env vars once and centralizes every tunable value,
  app, command, display, animation-adjacent setting and autostart entry.
- **domain/models.lua** defines pure data structures; **domain/constants.lua**
  holds static rules (no magic numbers, no hardcoded command strings).
- **domain/ports/** declares minimal contracts; **domain/ports/verify.lua**
  asserts an adapter implements them (fails loud on drift).
- **adapters/hyprland_adapter.lua** maps domain ops to `hl.*`; the pure
  translation lives in **adapters/hyprland_mappings.lua** and is unit-tested.
- **adapters/console_logger, system_time, process_lifetime** implement the
  cross-cutting `LoggerPort`, `TimePort` and `LifetimePort`. Transformation
  logic is extracted into pure helpers (`Logger.format_line`,
  `SystemTime.parse_uptime_ms`) so it is unit-tested without touching I/O.
- Every workflow reports `elapsed_ms` through `TimePort`, making load-time
  performance visible in the structured logs.
- **domain/workflows/*** receive `deps = { config, logger, time, lifetime,
  monitor, environment, input, binding, command, visual, layer, runtime,
  wallpaper }` and never read env or import adapters. Visual/input settings are
  passed as domain models (`VisualSettings`, `InputSettings`, `Device`); the
  adapter maps them to the compositor's `general`/`decoration`/`input` wire
  format.
- **adapters/hyprpaper_adapter.lua** implements `WallpaperPort`. It owns the
  hyprpaper external system end to end: `configure` writes the rendered config
  (`adapters/hyprpaper_mappings.lua` is pure) and `ensure_running` asks the
  injected `CommandPort` to launch the daemon idempotently. The `wallpaper`
  workflow builds `Wallpaper` models; the `wallpaper_daemon` workflow calls
  `ensure_running`, wired to both `hyprland.start` and `config.reloaded`, so the
  daemon is (re)started after a reload — not just on a fresh session.
- **hyprland.lua** reads config, creates adapters, verifies ports, injects
  `deps`, runs each load-time workflow inside an `xpcall` (logs the crash reason
  and re-raises), wires the `hyprland.start` event to the autostart and
  wallpaper-daemon workflows and `config.reloaded` to the wallpaper daemon, and
  reports total load time.

Note: bind actions use `hl.dsp.exec_cmd` (they build a dispatcher), while
autostart uses `hl.exec_cmd` (immediate spawn). `hyprland_mappings.lua` and the
adapter keep these two paths separate.

Note: Hyprland 0.55 runs Lua and removed the legacy `hyprctl keyword` /
`hyprpaper` config paths. Runtime adapters use the Lua API instead — e.g.
`scripts/toggle_display.py` issues `hyprctl eval 'hl.monitor({...})'` and the
hyprpaper config uses the `wallpaper { monitor = ... }` special category.

## Python helper scripts (hexagonal)

`scripts/` is a second, self-contained hexagon for the CLIs that run outside
the compositor's config load:

- **domain/** — pure `models`, `constants`, `errors`; small `ports/`
  (`Logger`, `TimePort`, `LifetimePort`, `Notifier`, `BatteryReader`,
  `SentMarkerStore`, `MonitorGateway`); pure `workflows/` for battery and
  display. No I/O, no adapter imports.
- **adapters/** — `hyprctl_monitors` (Lua runtime), `sysfs_battery`,
  `sent_marker_store`, `notify_send`, plus the cross-cutting `console_logger`,
  `system_time` and `process_lifetime`.
- **infra/** — `config.py` (the only env reader) and `paths.py` (XDG).
- **main.py** — composition root and CLI; verifies adapters against ports and
  dispatches `display-toggle` / `battery-notify`. The `toggle_display.py` and
  `battery-notify.py` paths remain as thin entry shims for existing callers.

```sh
just test-python-unit          # pytest scripts/tests/unit
just test-python-integration   # pytest scripts/tests/integration
just lint-python               # ruff check
just format-python             # ruff format
```

## Setup

1. Install dependencies from the repo root: `just deps`
2. Optional laptop variant: `HYPR_PROFILE=laptop`
3. Optional env overrides: `HYPR_TERMINAL`, `HYPR_BROWSER`, `HYPR_MENU`,
   `HYPR_LOG_LEVEL`, `HYPR_VOLUME_UP`, `HYPR_WALLPAPER`, `HYPR_WALLPAPER_CONF`,
   etc. (see `infra/config.lua`).

## Commands

```sh
just            # list recipes
just test       # unit + integration
just lint       # luacheck if available, else syntax check
just typecheck  # luac -p across every .lua file
just check      # lint + typecheck + test
just reload     # hyprctl reload
just dev        # reload on change (inotifywait), else tail logs
just logs       # tail the Hyprland log
```

## Keybindings

| Binding | Action |
|---------|--------|
| `SUPER + SHIFT + RETURN` | Terminal |
| `SUPER + Q` | Close window |
| `SUPER + H/J/K/L` | Focus left/down/up/right |
| `SUPER + SHIFT + H/J/K/L` | Move window |
| `SUPER + CTRL + H/J/K/L` | Resize window |
| `SUPER + ALT + U/J/H/G` | Move workspace to monitor |
| `SUPER + 1-0` | Switch workspace |
| `SUPER + SHIFT + 1-0` | Move window to workspace |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + B` | Toggle bar (Quickshell IPC) |
| `SUPER + N` | Toggle control center (Quickshell IPC) |
| `SUPER + SHIFT + N` | Clear notifications (Quickshell IPC) |
| `SUPER + P` | Open launcher (Quickshell IPC) |
| `SUPER + V` | Open clipboard history (Quickshell IPC) |
| `SUPER + L` | Lock session (Quickshell IPC) |
| `Print` / `SUPER + ALT + 4` | Region screenshot (Quickshell IPC) |
| `SUPER + M` | Toggle mirror/extend (Quickshell IPC for OSD) |
