# AGENTS.md — Quickshell config

Guidance for AI agents (and humans) working in this directory. This shell is built
with **Hexagonal Architecture (Ports & Adapters)** adapted to QML/Quickshell, using
an explicit **Contract Pattern** for every boundary.

If a change here can be made by introducing a contract instead of reaching across
modules, do that. The rules below are the definition of "correct" for this repo.

---

## 1. What this is

- A **Quickshell 0.3.x** configuration for Hyprland/Wayland, written in QML.
- Runs as a single long-lived process started by `qs` (see `justfile`).
- Entry point: `shell.qml` (`ShellRoot`) — the **composition root**.
- Current feature set: a top bar, a control center, an app launcher (menu),
  a clipboard history menu, a wallpaper switcher, and a notification daemon.

Read the upstream docs before touching service APIs:
**<https://quickshell.org/docs/v0.3.0/types/>**

---

## 2. Commands (DX)

The `justfile` here is a thin command index. Never put logic in it — it delegates.

| Command | What it does |
|---------|--------------|
| `just` / `just run` | Launch `qs` under a 4s timeout. Fails on any `ERROR` line. This is the only test. |

From the dotfiles root, `just shell run` routes here.

There is no separate test suite. Running `qs` loads `shell.qml` and every adapter
against its port, so a load error is the failure signal. Must be green before merge.

---

## 3. Architecture at a glance

Hexagonal architecture separates **what the shell does** (domain) from **how it
talks to the outside world** (adapters). QML has no `interface` keyword, so every
boundary is made explicit with a **contract**.

```
              DRIVING SIDE                                  DRIVEN SIDE
        (things that trigger us)                     (things we trigger)

   Hyprland keybind / IPC ─┐                    ┌─ Pipewire / UPower / Bluetooth
   Mouse / Keyboard ───────┤                    ├─ Networking / SystemTray
                           ▼                    │
   ┌──────────────────────────────────────────────────────────────┐
   │  DRIVING ADAPTERS        DOMAIN (pure)          DRIVEN ADAPTERS│
   │  Bar / ControlCenter  ┌──────────────────┐    PipewireAudio... │
   │  Menu / Clipboard  ──▶│ Ports  Workflows │◀── UPowerBattery... │
   │  Notifications        │ Models  Errors   │    BluetoothCli...   │
   │  (render + intents)   │ Constants        │    DesktopEntries... │
   │                       └──────────────────┘                      │
   └──────────────────────────────────────────────────────────────┘
                           ▲
                    shell.qml (composition root)
              creates adapters, injects them as ports
```

### Concept → QML/Quickshell mapping

| Hexagonal concept | In this repo |
|-------------------|--------------|
| Domain | Pure `.qml` under `domain/` — models, workflows, pure functions, constants, errors. No `Quickshell.*` imports. |
| Port | A `*Port.qml` file documenting a required capability, with default (null) values. The **contract**. |
| Driven adapter | A Quickshell service wrapper (`Quickshell.Io`, `Services.Pipewire`, `UPower`, `Bluetooth`, `Networking`, `Hyprland`, `SystemTray`, …) that fulfills a port by translating external state into domain values. |
| Driving adapter | A view/panel (`Bar`, `ControlCenter`, `Menus`, `Notifications`) that renders domain values and emits user intents. |
| Infra | `Theme.qml` design tokens, runtime config/env, logging sink. Cross-cutting only. |
| Composition root | `shell.qml` (plus root helpers). The only place that reads env, constructs adapters, and wires ports. |
| Entry point | `shell.qml`; admin actions via `IpcHandler` targets. |

---

## 4. The Contract Pattern (read this first)

Because QML is duck-typed, *the contract is the code*. A boundary is only real if
it is written down. Every port used here follows the same five rules:

1. **The port file is the single source of truth for the surface.**
   A `*Port.qml` declares only the properties (outputs), signals (events/intents),
   and functions (commands) that a consumer may rely on. The header comment
   documents each member, with **Pre/Post** clauses on commands and any
   **Invariant** on returned values. It holds a working *null* default, so the
   domain is always runnable without a real device.

   QML forbids a derived type from binding an inherited `readonly property`, so
   ports declare **plain** properties and mark them `(read-only)` in the header:
   only adapters bind them, consumers never write them. Ports also declare
   `default property list<QtObject> resources` so adapters can nest their
   private helpers (`Process`, `Timer`, `FileView`, trackers).

2. **Adapters extend the port and bind the surface.**
   A driven adapter is the port type with concrete bindings. It may hold extra
   private state, but it must not remove or change a member's meaning. This makes
   drift a type-level error instead of a runtime surprise.

3. **Consumers receive ports via `required property …Port`.**
   Domain workflows and views never import a concrete adapter and never touch a
   Quickshell service directly. They depend on the port type only.

4. **The composition root injects.**
   `shell.qml` creates one adapter instance per capability and hands it to the
   views/workflows. Swapping real → fake happens here, not inside components.

5. **Every port is checked by the running shell.**
   `just run` loads each adapter against its port type. A new adapter is not "done"
   until `just run` is clean with it wired in `shell.qml`.

### Design by contract

Every port command states three kinds of clause. Each is enforced where it applies:

- **Precondition (the caller's obligation).** Checked before any side effect, at the
  top of the adapter's command, with `Errors.precondition(...)`. A failure throws a
  `ValidationError`. Example: `setVolume` requires a finite value within `0..Bounds.volumeMax`.
- **Postcondition (the backend's obligation).** Checked where backend data enters the
  shell, with `Errors.postcondition(...)`. A failure throws a `ContractViolation`.
  Example: `PowerProfilesAdapter` throws on an unknown daemon profile instead of
  mapping it to `"Balanced"`.
- **Invariant (always true of a model).** A pure predicate in `domain/models/`, for
  example `ClipboardModel.holdsInvariant(history, limit)`.

Clause predicates are pure functions in `domain/models/Contracts.qml` (and the topic
singletons such as `ClipboardModel.qml`). `domain/errors/Errors.qml` builds the error
values and provides the two guards. Bounds are named in `domain/constants/Bounds.qml`.

Expected outcomes are not contract violations. An absent device, an unknown desktop
entry, or a vanished network is logged with `console.warn` and returned through the
port's normal path. Only defects throw. `just run` only sees the first 4 seconds of
output, so a violation at runtime shows up in the `qs` log, not in the gate.

### Example — a port

```qml
// domain/ports/BatteryPort.qml
// CONTRACT — BatteryPort (all members read-only by contract)
//   bool   present   laptop battery exists
//   int    level     0-100
//   bool   charging
//   string state     "Charging"|"Discharging"|"Full"|"Plugged in"|"Unknown"
//   string timeText  human remaining/until-full, "" when unknown
import QtQml

QtObject {
  property bool present: false
  property int level: 0
  property bool charging: false
  property string state: "Unknown"
  property string timeText: ""

  default property list<QtObject> resources
}
```

### Example — a driven adapter

```qml
// adapters/driven/upower/UPowerBatteryAdapter.qml
import Quickshell.Services.UPower
import "../../../domain/ports"

BatteryPort {
  id: root
  readonly property var device: UPower.displayDevice

  present:   device !== null && device.ready && device.isLaptopBattery
  level:     device ? Math.round(device.percentage * 100) : 0
  charging:  device !== null && device.state === UPowerDeviceState.Charging
  state:     charging ? "Charging"
           : device && device.state === UPowerDeviceState.Discharging ? "Discharging"
           : device && device.state === UPowerDeviceState.FullyCharged ? "Full"
           : device && device.state === UPowerDeviceState.PendingCharge ? "Plugged"
           : "Unknown"
  timeText:  "" // derived by a pure domain function, not here
}
```

### Example — a view consuming the port

```qml
// adapters/driving/bar/Battery.qml
import "../../../domain/ports"
RowLayout {
  required property BatteryPort batteryPort
  visible: batteryPort.present
  // ... render batteryPort.level / batteryPort.state / batteryPort.timeText
}
```

### Example — the composition root wiring

```qml
// shell.qml
ShellRoot {
  UPowerBatteryAdapter { id: battery }
  PipewireAudioAdapter  { id: audio }

  Bar { batteryPort: battery; audioPort: audio }
}
```

### Domain workflows: pure orchestrators

A workflow coordinates pure functions and port calls. Keep each line one intent.

```qml
// domain/workflows/VolumeWorkflow.qml
import QtQml
import "../ports"
import "../constants" as C

QtObject {
  required property AudioPort audioPort
  function setVolume(requested) {
    if (!Number.isFinite(requested)) return
    audioPort.setVolume(Math.max(C.MIN_VOLUME, Math.min(C.MAX_VOLUME, Math.round(requested))))
  }
}
```

---

## 5. Layers

### Domain (`domain/`) — pure, no Quickshell
- `models/` — `pragma Singleton` QML types holding pure functions (`Contracts`, `Sinks`, `ClipboardModel`, `NotificationModel`, …) and the plain data shapes they build.
- `workflows/` — orchestrate pure functions + ports (`VolumeWorkflow`, `ClipboardHistoryWorkflow`).
- `ports/` — one `*Port.qml` per capability (see §4).
- `constants/` — static business constants. **No magic numbers.** No env reads.
- `errors/Errors.qml` — `ValidationError` / `ContractViolation` values and the `precondition` / `postcondition` guards.
- Pure transforms that currently live inline (app-list filtering, `Exec` tokenizing,
  signal/icon tiering, notification timeout math, clipboard text validation) move
  here as pure functions. That is the highest-value refactor in this repo.

Domain **must not** `import Quickshell` or `Quickshell.*`. `import QtQml` for `QtObject`
and `import QtQuick` for layout-neutral value types are tolerated; service modules are not.

### Ports (`domain/ports/`)
- One capability per file, named `<Capability>Port.qml` (`AudioPort`, `BatteryPort`,
  `NetworkPort`, `BluetoothPort`, `WorkspacePort`, `NotificationFeedPort`, `LoggerPort`,
  `ClockPort`, `LaunchPort`, `ClipboardPort`, `WallpaperPort`, `LifetimePort`).
- The file header is the authoritative contract. Update it when the surface changes.
- Add a port only when the [Port Taxonomy](https://github.com/shawal-mbalire/shawal_stack/blob/main/hexagonal_architecture.md)
  trigger fires: a real external dependency, a substitution/test need, ≥2 implementations,
  or required determinism. Pure logic is not a port.

### Adapters (`adapters/`)
- `driven/` — implement ports against the outside world.
  - One adapter = one external system (`adapters/driven/pipewire/`, `.../upower/`,
    `.../bluetooth/`, `.../network/`, `.../hyprland/`, `.../notifications/`,
    `.../desktop-entries/`, `.../shell-process/`).
  - Constructor-injected config: pass a frozen config object as a property; **never
    read `Quickshell.env` inside an adapter** (only the composition root/infra does).
  - Translate vendor shapes into domain values at this boundary (the DTO boundary).
  - Translate failures into a domain error + emit a `LoggerPort` entry; never swallow.
- `driving/` — render and emit intents.
  - `driving/shared/` — presentation primitives (`Card`, `Pill`, `Slider`, `Overlay`).
  - `driving/bar/`, `driving/control-center/`, `driving/menus/`, `driving/notifications/`
    — feature views.
  - A view has **no `Process`, `FileView`, or service imports**. It binds *ports* and
    emits *intent signals*. Writes go through the port, never `Quickshell.execDetached`.

### Infra (`infra/`)
- Config and cross-cutting plumbing only.
- `infra/config/` — `Theme.qml` (design tokens) and a `Config.qml` singleton that is the
  **only** place `Quickshell.env()` / `Quickshell.shellDir` are read.
- Logging is an adapter (`LoggerPort` implementation), **not** infra.
- No app logic, no ports, no models here.

### Composition root (`shell.qml`)
Reads config → creates adapters → wires ports → starts the driving surface.
No business logic. Entry points read like a shell script:

```qml
ShellRoot {
  Config { id: config }
  LoggerAdapter { id: logger }

  UPowerBatteryAdapter { id: battery }
  PipewireAudioAdapter  { id: audio }
  HyprlandWorkspaceAdapter { id: workspaces }

  VolumeWorkflow { audioPort: audio; loggerPort: logger }

  Bar { batteryPort: battery; audioPort: audio; workspacePort: workspaces }
}
```

---

## 6. Target layout & migration map

The architecture uses **three root directories** (`domain/`, `infra/`, `adapters/`) plus root-level entry files.
Adopt incrementally — when you touch a feature, move its pieces to their home.

```
quickshell/
├── shell.qml                     # composition root (entry point)
├── AGENTS.md
├── justfile
├── domain/                       # pure; imports QtQml only
│   ├── constants/                # static bounds + pure policies (qmldir)
│   ├── errors/Errors.qml         # contract errors and guards (DbC)
│   ├── models/                   # pure JS data shapes, transforms and clause predicates
│   └── ports/                    # *Port.qml contracts (Pre/Post/Invariant headers)
├── infra/
│   └── config/                   # Config.qml (env), Theme.qml (design tokens), qmldir
├── adapters/
│   ├── driven/                   # flat: one file per external system, <System>Adapter.qml
│   └── driving/                  # PascalCase feature folders: views that render ports and emit intents
│       ├── Bar/
│       ├── ControlCenter/
│       ├── Menus/
│       ├── Notifications/
│       └── Shared/               # presentation primitives (Card, Pill, Slider, Overlay, Osd, …)
└── build/                        # gitignored, recreatable, never committed
```

Flat `driven/` files are deliberate: a folder per adapter with one file each breaks
"files over folders". Create a `driven/<system>/` folder only when a system has 3+ files.

| Current file | Location |
|--------------|----------|
| `shell.qml` | root — composition root |
| `infra/config/Theme.qml`, `Config.qml` | `infra/config/` |
| `adapters/driving/Shared/*` | presentation primitives and overlay plumbing |
| `adapters/driving/Bar/*` | bar widgets; service reads go through ports into `adapters/driven/` |
| `adapters/driving/ControlCenter/ControlCenter.qml` | view; device I/O lives in driven adapters |
| `adapters/driving/Menus/*` | launcher, clipboard, wallpaper IPC; search and history logic in `domain/models/` |
| `adapters/driving/Notifications/Notifications.qml` | notification popups and history, rendered through `NotificationFeedPort`; the daemon lives in `NotificationServerAdapter.qml` |

**Migrated so far** (ports in `domain/ports/`, adapters wired in `shell.qml`):
Audio (`pipewire/`), Battery (`upower/`), Bluetooth (`bluetooth/`), Brightness
(`brightness/`), Network (`network/`), ColorCorrection (`gammastep/`), Clipboard
(`wl-clipboard/`), Launch (`desktop-entries/`), Power profiles (`upower/`),
colour scheme (`gsettings/`), Notifications (`NotificationServerAdapter`),
Workspaces (`HyprlandWorkspaceAdapter`), Wallpapers (`HyprlandWallpaperAdapter`).
Pure helpers live in `domain/models/*.qml` singletons. Views live under
`adapters/driving/` and consume ports only.
Not yet migrated: system tray (`Bar/SystemTray.qml` still uses `Quickshell.Services.SystemTray`
directly; its menus need a decision on how `QsMenuAnchor` handles cross the port).

**Performance rules learned here**
- Overlays (menu, clipboard, control center) are created by a `LazyLoader` on
  the focused monitor only, never one per screen kept alive while hidden.
- One adapter instance per capability, shared by every screen; never a
  `Timer`+`Process` inside a per-screen view.
- Prefer event-driven typed services; if polling is unavoidable (sysfs), poll a
  file with `FileView.reload()`, not a spawned process.
- Use per-item `NumberAnimation`s for progress bars, not a global ticking `Timer`.
- Never size a window from a `ListView`'s `contentHeight` (0px ListViews create
  no delegates); use `Column` + `Repeater` for short, auto-sized lists.
- Hyprland runs in Lua mode: `Hyprland.dispatch` must branch on
  `Hyprland.usingLua` (`hl.dsp.focus({ workspace = N })`).
- Never activate a `HyprlandFocusGrab` in the same frame its window maps;
  Hyprland clears it at once and the popup closes instantly (broke SUPER+N).
  Use `Shared/DismissGrab.qml`, which arms late and only dismisses after a
  grab really engaged.
- Overlays animate through `Shared/Overlay.qml` (`open` drives enter/exit,
  `closed()` fires after the exit animation) and are mounted by a
  `Shared/OverlaySlot.qml` in `shell.qml`, so windows outlive their exit
  animation. Motion durations/easings are tokens in `Theme.qml`.
- Never name a property after an `Item` member (`enabled`, `focus`,
  `visible`, …) in a view; it silently shadows it.
- Never bind a layer surface's size to content that animates. Each frame resizes the
  Wayland surface and the window flickers. Size the window once, animate the panel
  inside it, and pass clicks through the empty area with `mask: Region { item: panel }`.
  The control center does this; overlays that grow or shrink should follow it.
- Overlays hang below the bar (`margins.top: Theme.barHeight`), never over it.
- The hot corner opens the control center only after a dwell (`dwellMs`), at most once
  per visit. Hovering it reveals the bar at once. Do not make it fire on entry.

**Sound rules**
- Writes are capped at `Bounds.volumeMax` (100%). Lowering is always allowed, so a sink
  already boosted past the cap can still be turned down; raising above it is refused by
  the precondition. Do not raise the cap to make a control work.
- No feedback tone while muted. The composition root gates `playTone` on `audio.muted`.
- The tone player is probed once at startup (`command -v ffplay`) and feedback is disabled
  when it is missing.
- A tone is killed by a watchdog after `maxPlayMs`, so a hung player cannot block later
  tones. Three consecutive failures disable feedback for the session, with a warning.
- **Never output to an AirPlay (RAOP) sink or the Mac mini.** `domain/models/Sinks.qml`
  excludes them by name and description. They are never listed in `sinks`, and the
  adapter moves the default off them. Do not add them back, and do not add a bypass.
- **HDMI / DisplayPort outputs are not sinks either.** They are listed by the sound
  card even when unplugged, so the laptop's built-in speakers are the single output.
  `Sinks.qml` excludes them the same way.
- `QS_PREFERRED_SINK=<node.name>` names the fallback sink (the `node.name` is in
  `pw-cli`/`wpctl`, e.g. `alsa_output....HiFi__Speaker__sink`). When the default is not
  eligible, the adapter steers it there, or else to the first eligible sink.
  `hypr/lua/autostart.lua` sets it when it starts `qs`.
- Choose the default in the shell with `setDefaultSink(name)`, which also updates the
  preference. Never write to Pipewire from a view.

**File placement decision tree** — every new file lands in one of the three roots:

```
Is it an entry point?              → root file (e.g. shell.qml)
Is it a contract/interface?        → domain/ports/
Is it a pure data shape?           → domain/models/
Is it workflow orchestration?      → domain/workflows/
Is it a constant / error?          → domain/constants/ · domain/errors/
Is it a driven adapter?            → adapters/driven/<System>Adapter.qml
Is it a view?                      → adapters/driving/<Feature>/
Is it config or cross-cutting?     → infra/
Otherwise: it belongs inside an existing file — do NOT add a fourth root directory.
```

Prefer **files over folders**: only make a folder when it will hold 3+ files.
2-space indent, one component per file, `id: root` on the outer component.

### Naming conventions (case-sensitive filesystem)

QML imports are **case-sensitive** on Linux, so a directory import must match the
on-disk name exactly. There is no auto-correct — a wrong case is a load failure.

| Kind | Case | Examples |
|------|------|----------|
| Feature / module directories (**larger imports**) | `PascalCase` | `Bar/`, `Menus/`, `Shared/`, `ControlCenter/` |
| Component files and type names (**larger imports**) | `PascalCase` | `ControlCenter.qml`, `Audio.qml`, `Theme.qml` |
| Architecture / plumbing directories (**smaller imports**) | `lowercase` | `domain/`, `infra/`, `ports/`, `adapters/` |
| `qmldir` module URIs | `lowercase` | `module shared` |
| `id`s, properties, functions, signals (**smaller imports**) | `lowerCamelCase` | `id: root`, `barVisible`, `setVolume` |
| Pure-logic singletons (`pragma Singleton` in `domain/`) | `PascalCase` | `Contracts.qml`, `ClipboardModel.qml`, `Errors.qml` |
| Quickshell module imports | `PascalCase` segments | `Quickshell.Io`, `Quickshell.Services.Pipewire` |

Rules of thumb:
- A directory that bundles a **feature/big unit** is PascalCase; a directory that is
  **plumbing/support** is lowercase.
- Every request to rename a directory must be paired with updates to every import
  that references it, and all `qmldir` entries. Grep the old name before finishing:
  `grep -rn 'OldName' .` must return nothing outside git history.

Verify a rename with:
```sh
grep -rnE 'import "' --include='*.qml' .   # every directory import
find . -maxdepth 2 -type d                # actual on-disk names
```

---

## 7. Rules

1. **Dependencies point inward.** Adapters depend on Domain. Domain never imports adapters, `Quickshell`, or services.
2. **The contract is the port file.** A `*Port.qml` is the one place its surface is defined; adapters extend it, consumers require it.
3. **Never import a concrete adapter outside `shell.qml`.** If a view needs a capability, inject a port.
4. **The DTO boundary is real.** Adapters translate service/CLI/D-Bus shapes into domain values. No raw `UPowerDevice`, `Network`, or process output leaks into domain or views.
5. **Views don't do I/O.** No `Process`, `FileView`, `execDetached`, or service imports in `adapters/driving/`. Emit intents; the port acts.
6. **Composition root is the only wiring point.** Only it reads config and constructs adapters. It contains no logic.
7. **No magic numbers in domain.** Name them in `domain/constants/`. Configurable values come from `infra/config`.
8. **Prefer typed service adapters over shell-outs.** Use `Quickshell.Bluetooth`, `Networking`, `Services.Pipewire`, `Services.UPower`, `Hyprland`, `Services.SystemTray`, `Services.Mpris` where the API exists. Shelling out (`nmcli`, `bluetoothctl`, `wpctl`, `brightnessctl`) is a fallback adapter only, and lives in exactly one driven adapter.
9. **Every function pure by default.** Extract pure transforms (`tokenizeExec`, `isUsableText`, `timeoutFor`, icon/signal tiering, filters) into pure functions. Impure code is only the thin I/O methods in adapters and the wiring in `shell.qml`.
10. **Workflows read like pseudocode.** One intent per line: validate → act → report.
11. **Fail fast, never fail silent.** Validate at the boundary; surface errors through `LoggerPort`; handle `onExited` non-zero codes explicitly. No empty `catch`, no `|| true` hidden behind a view.
12. **TimePort / LifetimePort equivalents.** Use a `ClockPort` (backed by `SystemClock`) instead of scattered `Date.now()`, and a `LifetimePort` (backed by `Component.onDestruction` / shell shutdown) to stop processes/timers and flush state on reload/exit.
13. **Portable adapters.** An adapter file copies to another project with only its driver + standard ports: no app imports, config injected, vendor errors translated, mapping pure.
14. **Keep it shippable.** Don't big-bang refactor. Extracting one adapter/port at a time is a complete change; migrate the touched feature and leave the rest.
15. **Reproducible.** No global RNG/time in domain; inject `ClockPort`. Pin no hidden state in singletons beyond config/logging.
16. **No JavaScript files.** Pure logic is a `pragma Singleton` QML type in `domain/`, registered in its folder's `qmldir`. Constants are `readonly property`. Consumers import the folder (`import "../../domain/models"`) and call the type by name. Do not add `.js` files, and do not add `.js` imports.

---

## 8. Quickshell API surface (what maps where)

| Module (`import`) | Used for | Adapter location |
|-------------------|----------|------------------|
| `Quickshell` | `ShellRoot`, `PanelWindow`, `Variants`, `IpcHandler`, `Quickshell.screens/env/execDetached`, `SystemClock`, `ScriptModel` | root + driving adapters |
| `Quickshell.Io` | `Process`, `SplitParser`, `StdioCollector`, `FileView` | driven adapters only |
| `Quickshell.Services.Pipewire` | audio sinks/sources, volume | `adapters/driven/pipewire/` |
| `Quickshell.Services.UPower` | battery, power profiles | `adapters/driven/upower/` |
| `Quickshell.Services.Notifications` | `NotificationServer`, urgency | `adapters/driven/NotificationServerAdapter.qml` |
| `Quickshell.Networking` | Wi-Fi/Ethernet state | `adapters/driven/network/` |
| `Quickshell.Bluetooth` | adapter/devices/pairing | `adapters/driven/bluetooth/` |
| `Quickshell.Hyprland` | workspaces, dispatch | `adapters/driven/hyprland/` |
| `Quickshell.Services.SystemTray` | tray items/menus | `adapters/driven/system-tray/` |
| `Quickshell.Services.Mpris` | media players | `adapters/driven/mpris/` |
| `Quickshell.Wayland` | layer-shell namespace/focus | driving adapters |
| `Quickshell.Io` + `Process` | brightnessctl, gammastep, wl-clipboard, ls | one driven adapter per tool |

Reference: <https://quickshell.org/docs/v0.3.0/types/>

---

## 9. Verification

- There is no test suite. `just run` is the gate: it starts `qs`, loads `shell.qml`
  and every adapter, and fails on any `ERROR` line.
- Check a change by running the shell and exercising the feature (bar, control center,
  launcher, clipboard, notifications) on a live Hyprland session.
- Every driven adapter must handle its failure paths explicitly: non-zero exits,
  missing devices, and malformed output are logged through `console.warn` and never ignored.

---

## 10. Error handling & diagnostics

- A defect throws a contract error from `domain/errors/Errors.qml`: `kind` (`ValidationError`
  or `ContractViolation`), a stable `code`, and structured `context`. Never a bare
  string, never a raw service error.
- An expected outcome is logged and returned through the port, not thrown.
- Adapters report through `LoggerPort`; the dev implementation logs structured lines
  (`console.warn`/`console.error` are acceptable until a file sink exists), and is
  swappable. Logging is an adapter, never inline `console.log` in domain.
- Non-zero `Process` exits, missing `FileView` paths, and null service objects are
  handled explicitly and surfaced — never silently ignored.

---

## 11. Anti-patterns (do not do these)

- `import Quickshell.*` inside `domain/`.
- A view instantiating `Process`/`FileView` or calling `Quickshell.execDetached`.
- Reaching into a sibling feature's internals instead of a port.
- Injecting a concrete adapter instead of its port.
- Business logic in `shell.qml`.
- Magic numbers in domain code.
- Adding a fifth root directory for "just one file".
- Silent failure (empty catch, ignored exit code, `|| true` masking).
- A `.js` file anywhere in the shell. Pure logic goes in a `pragma Singleton` QML type (rule 16).
- Coupling `Theme` (config) to behavior logic.

---

## 12. New-feature checklist

```
Adding or changing a capability?
├─ Name the contract first: write/extend domain/ports/<Capability>Port.qml with Pre/Post/Invariant
├─ Add clause predicates to domain/models/Contracts.qml; guard them in the adapter with Errors.precondition / postcondition
├─ Add static constants to domain/constants/ (no magic numbers)
├─ Extract pure logic into domain/ (models, functions, workflows)
├─ Implement the driven adapter as adapters/driven/<System>Adapter.qml (typed service first)
├─ Keep the driving view I/O-free: require the port, emit intents
├─ Wire it once in shell.qml (create adapter, inject port)
├─ Register any new error code
├─ Verify: `just run` clean, no Quickshell imports in domain/
└─ Touch nothing else — the migration is incremental
```

---

## 13. References

- Quickshell types: <https://quickshell.org/docs/v0.3.0/types/>
- Hexagonal architecture (source skill): <https://github.com/shawal-mbalire/shawal_stack/blob/main/hexagonal_architecture.md>
- Architecture diagram: <https://github.com/shawal-mbalire/shawal_stack/blob/main/architecture-diagram.md>
