# Quickshell config: design choices

A [Quickshell](https://quickshell.org) 0.3 shell for Hyprland on Wayland. It draws
the top bar, control center, launcher, clipboard history, wallpaper switcher,
notification popups, and the volume and brightness OSD.

This document explains why the code is shaped the way it is. The rules that
contributors must follow live in [AGENTS.md](AGENTS.md). Read that before changing
the code.

## Architecture: ports and adapters

The shell follows hexagonal architecture (ports and adapters), adapted to QML.
QML has no `interface` keyword, so each boundary is written down as a file.

```
driving side (triggers the shell)          driven side (the shell triggers)
  Bar, ControlCenter, Menus,                 Pipewire, UPower, BlueZ,
  Notifications                              NetworkManager, Hyprland, gsettings,
        │                                    wl-clipboard, desktop entries, MPRIS
        ▼                                          ▲
  ┌────────────────────── domain (pure) ──────────────────────┐
  │ ports/  workflows/  models/  constants/  errors/          │
  └───────────────────────────────────────────────────────────┘
```

- **Domain** (`domain/`) holds pure logic and imports no `Quickshell.*` module.
- **Ports** (`domain/ports/*Port.qml`) are the contracts. Each one declares the
  properties, signals, and functions a consumer may rely on, and the header comment
  states the pre- and postconditions.
- **Driven adapters** (`adapters/driven/`) implement ports against the outside world.
  Each adapter translates vendor objects into plain domain values at its boundary.
- **Driving adapters** (`adapters/driving/`) are the views. They bind ports, render
  values, and emit intents. They never import a service or start a process.
- **Composition root** (`shell.qml`) is the only place that creates adapters and
  injects them into ports and views. It contains no business logic.

### Why this shape

The shell talks to many independent system services (audio, Bluetooth, network,
brightness, notifications). Keeping the vendor APIs behind ports has three effects:

- **Views are replaceable.** The control center can be redrawn without touching
  BlueZ or PipeWire.
- **Failure handling is in one place.** Each adapter translates vendor errors into
  a domain value or a domain error, so no raw process output leaks into the UI.
- **Adapters can be swapped.** When a typed Quickshell service exists, it replaces a
  shell-out. The views don't change.

### Why contracts are files

Every port documents its surface in a header, and an adapter must extend the port
type. This makes drift a type-level error. Consumers receive a port through
`required property`, so they can't reach past it to a concrete adapter.

## Pure logic lives in QML singletons, not JavaScript

Pure functions (filters, parsers, timeout math, validation, contract predicates)
are `pragma Singleton` QML types in `domain/`, and each folder's `qmldir` registers
them. Constants are `readonly property`.

The shell used to keep this logic in `.js` files. They were removed for three
reasons:

- **One language and one loader.** Every domain module is a QML type. There is no
  second module system with its own import syntax and `.pragma library` rules.
- **Typed constants.** `readonly property int` is checked where it is used.
  A `.js` `const` is not.
- **Consistent imports.** Consumers write `import "../../domain/models"` and call
  `Contracts.isBool(...)`, the same way they use every other domain type.

The rule is written into AGENTS.md (rule 16), so new JavaScript files are not
accepted.

## Contracts: Pre, Post, and Invariant

Ports follow design by contract:

- **Precondition** (caller's obligation). Checked before any side effect and thrown
  as a `ValidationError`. Example: `setVolume` rejects values above the volume cap.
- **Postcondition** (backend's obligation). Checked where backend data enters the
  shell and thrown as a `ContractViolation`. Example: an unknown power-profile name
  is an error, not silently mapped to "Balanced".
- **Invariant** (always true of a model). A pure predicate, for example "clipboard
  history is usable, unique, and bounded".

Expected outcomes are not errors. An absent device, an unknown network, or a
vanished desktop entry is logged with `console.warn` and returned through the
port's normal path. Only defects throw. This keeps the log meaningful: a warning
means the environment changed, and an error means the code is wrong.

## Performance choices

Quickshell runs for days at a time, so the design favours events over loops:

- **Event-driven services.** Audio, battery, Bluetooth, network, MPRIS, and
  Hyprland state come from typed Quickshell services, which push changes. Nothing
  polls them.
- **Polling only where the kernel offers no events.** Brightness reads a sysfs file
  with `FileView.reload()` every two seconds, and the Hyprland brightness keys call
  `qs ipc call brightness refresh` so the shell updates at once. The poll is only a
  fallback. The shell and the keys share brightnessctl's `-e4` curve
  (`domain/models/BrightnessCurve.qml`), so the readout matches what the keys set.
  Gammastep is checked with `pgrep` once a minute and whenever the control center
  opens, because it exposes no state file.
- **One adapter per capability, shared by every screen.** There is one audio
  adapter, not one per monitor. Per-screen views never start their own `Timer` or
  `Process`.
- **Overlays mount on demand.** The menu, clipboard, and control center are created
  by a `LazyLoader` on the focused monitor only, and destroyed after their exit
  animation. An idle shell holds no overlay windows.
- **Per-item animations.** Progress bars use a `NumberAnimation` on each item rather
  than a global ticking `Timer` that re-evaluates every binding.
- **No `ListView` for window sizing.** A 0 px `ListView` creates no delegates, so a
  window sized from its `contentHeight` came up empty. Short lists use a `Column`
  with a `Repeater`.
- **Coalesced writes.** Slider drags to brightness are coalesced, because
  `brightnessctl` finishes slower than a drag produces events.

## Bar behaviour

The bar is auto-hidden so it does not take screen space from tiled windows.
Four things reveal it: a pointer at the top edge, a pointer in the top-right hot
corner, a pinned toggle over IPC, or the control center being open. Hiding is
deferred by 500 ms, so the pointer can cross from the bar to the edge strip without
flicker.

- The bar uses `exclusiveZone: 0`, so showing or hiding it never reflows windows.
- The hot corner opens the control center only after a dwell, and at most once per
  visit. Hovering reveals the bar at once.
- Overlays hang below the bar (`margins.top: barHeight`) and never cover it.

## Overlays and windows

Overlays animate through `Overlay.qml`. `open` drives the enter and exit animations,
and `closeFinished` fires after the exit animation. The window is destroyed only
then, so the exit animation is not cut off.

- **Size windows once.** A layer surface resized every frame flickers. The control
  center sizes its window once, animates the panel inside it, and passes clicks
  through the empty area with `mask: Region { item: panel }`.
- **Don't activate a focus grab in the frame the window maps.** Hyprland clears it
  immediately and the popup closes. `DismissGrab` arms late and dismisses only after
  the grab has really engaged.

## Notifications

The notification daemon is a driven adapter (`NotificationServerAdapter`). Views
render `NotificationFeedPort` and emit intents. The adapter keeps the vendor
`Notification` objects private and reports only plain values.

- **Exit phases.** A popup that is closing has a phase: `dismiss`, `expire`, or
  `closed`. The view plays the exit animation, then calls `finish`. Only then does the
  sender hear back. A sender that closed its own notification is not called back.
- **Overflow expires at once.** When more than `maxVisible` popups are shown, the
  oldest one is expired immediately, without an animation.
- **Shell-originated notices.** The Bluetooth and network workflow posts its own
  connect and disconnect notices through the same feed. It diffs snapshots of the
  connected devices or SSID, so an unchanged state never notifies.

## Audio safety

These rules come from real incidents and are enforced in code:

- Volume writes are capped at 100%. Lowering is always allowed, so a sink that was
  boosted past the cap can still be turned down.
- No feedback tone plays while muted.
- AirPlay (RAOP) sinks, including the Mac mini, are never listed and never used as
  output. The filter lives in `domain/models/Sinks.qml`.
- Feedback tones are killed by a watchdog after `maxPlayMs`, so a hung player cannot
  block later tones. Three consecutive failures disable feedback for the session.

## Naming and layout

- **Files over folders.** A folder is made only when it will hold three or more
  files.
- **Case-sensitive names matter.** QML directory imports must match the on-disk
  name, and Linux does not correct the case. Feature folders and component files are
  `PascalCase`. Architecture folders are `lowercase`.
- **No fourth root directory.** Every file lives under `domain/`, `infra/`, or
  `adapters/`, or in the root.

## Known gaps

- **System tray is not migrated.** `Bar/SystemTray.qml` still uses
  `Quickshell.Services.SystemTray` directly. Its menus are `QsMenuAnchor` objects,
  which must anchor to a view item. Moving them behind a port needs a design decision
  about how a menu handle crosses the boundary.
- **No automated tests.** The gate is `just run`, which starts `qs` for four seconds
  and fails on any `ERROR` line. Behaviour that depends on a live session, such as
  Hyprland, Bluetooth, or Wi-Fi events, must be checked by hand.

## Running

```sh
just            # same as `just run`
```

From the dotfiles root, `just shell run` runs the same gate. The shell is started
by `qs` from `hypr/lua/autostart.lua`.
