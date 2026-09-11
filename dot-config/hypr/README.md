# Hyprland Config (Hexagonal Architecture)

Domain owns the config logic. Adapters translate to the `hl.*` API. Infra reads
env vars. The composition root wires everything together.

## Structure

```
├── domain/                     # Pure application logic (no hl.*, no env)
│   ├── models.lua              # Color, Bezier, Anim, Bind, Display, LayerRule,
│   │                           #   VisualSettings, InputSettings, Device
│   ├── constants.lua           # Static rules: RESIZE_STEP, MAX_WS, curves,
│   │                           #   layers, EVENTS, ACTION vocabulary
│   ├── ports/                  # Small port contracts + verify.lua conformance check
│   │   ├── monitor.lua  environment.lua  input.lua  binding.lua
│   │   ├── command.lua  visual.lua  layer.lua  runtime.lua
│   │   └── logger.lua  time.lua  lifetime.lua
│   └── workflows/              # Orchestration, dependencies injected as `deps`
│       ├── displays.lua  env.lua  look.lua  input.lua
│       └── keybindings.lua  windows.lua  autostart.lua
├── adapters/                   # Plumbing: implement ports against external systems
│   ├── hyprland_adapter.lua    # Implements the Hyprland ports via hl.*
│   ├── hyprland_mappings.lua   # Pure DTO mapping (Display -> rule, action -> dispatcher)
│   ├── console_logger.lua      # LoggerPort
│   ├── system_time.lua         # TimePort
│   └── process_lifetime.lua    # LifetimePort
├── infra/
│   └── config.lua              # Env vars read HERE only
├── tests/
│   ├── fixtures/               # fakes.lua (in-memory ports), fake_hl.lua
│   ├── unit/                   # models, constants, mappings, adapter, workflows
│   └── integration/            # loads the real composition root against fake hl
├── scripts/                    # External driven adapters + devtool (Python):
│                               #   toggle_display.py, battery-notify.py, dev.py
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
  cross-cutting `LoggerPort`, `TimePort` and `LifetimePort`.
- **domain/workflows/*** receive `deps = { config, logger, time, lifetime,
  monitor, environment, input, binding, command, visual, layer, runtime }` and
  never read env or import adapters. Visual/input settings are passed as domain
  models (`VisualSettings`, `InputSettings`, `Device`); the adapter maps them to
  the compositor's `general`/`decoration`/`input` wire format.
- **hyprland.lua** reads config, creates adapters, verifies ports, injects
  `deps`, runs each load-time workflow inside an `xpcall` (logs the crash reason
  and re-raises), wires the `hyprland.start` event to the pure autostart
  workflow, and reports total load time.

Note: bind actions use `hl.dsp.exec_cmd` (they build a dispatcher), while
autostart uses `hl.exec_cmd` (immediate spawn). `hyprland_mappings.lua` and the
adapter keep these two paths separate.

## Setup

1. Install dependencies from the repo root: `just deps`
2. Optional laptop variant: `HYPR_PROFILE=laptop`
3. Optional env overrides: `HYPR_TERMINAL`, `HYPR_BROWSER`, `HYPR_MENU`,
   `HYPR_LOG_LEVEL`, `HYPR_VOLUME_UP`, etc. (see `infra/config.lua`).

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
| `SUPER + B` | Toggle waybar |
| `SUPER + M` | Toggle mirror/extend |
