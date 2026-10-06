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
| `just` / `just run` | Launch `qs` under a 4s timeout, print only `ERROR` lines. The smoke test. |
| `just verify` | *(target)* lint + all test tiers. Must be green before merge. |
| `just test` | *(target)* run the `tests/` suites. |

From the dotfiles root, `just shell run` routes here.

**Tooling note:** this machine currently has `qs` but not `qmllint`/`qmltestrunner`
(package `qt6-qttools`). Until installed, `just run` is the only automated gate;
add the tools rather than hand-waving a "verify" step.

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
| Domain | Pure `.qml`/`.js` under `domain/` — models, workflows, pure functions, constants, errors. No `Quickshell.*` imports. |
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
   documents each member. It holds a working *null* default, so the domain is
   always runnable without a real device.

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

5. **Every port has a contract test.**
   `tests/contract/` instantiates each adapter and asserts it satisfies the port
   surface and semantics. A new adapter is not "done" until its contract test is.

### Example — a port

```qml
// domain/ports/BatteryPort.qml
// CONTRACT — BatteryPort
//   readonly int    level     0-100
//   readonly bool   present   laptop battery exists
//   readonly bool   charging
//   readonly string state     "Charging"|"Discharging"|"Full"|"Plugged"|"Unknown"
//   readonly string timeText  human remaining/until-full, "" when unknown
import QtQml

QtObject {
  readonly property int level: 0
  readonly property bool present: false
  readonly property bool charging: false
  readonly property string state: "Unknown"
  readonly property string timeText: ""
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
- `models/` — plain `QtObject`s and `.js` data shapes (an `AppEntry`, a `NotificationEntry`).
- `workflows/` — orchestrate pure functions + ports (`VolumeWorkflow`, `ClipboardHistoryWorkflow`).
- `ports/` — one `*Port.qml` per capability (see §4).
- `constants/` — static business constants. **No magic numbers.** No env reads.
- `errors/` — domain error types/values.
- Pure transforms that currently live inline (app-list filtering, `Exec` tokenizing,
  signal/icon tiering, notification timeout math, clipboard text validation) move
  here as functions and get unit tests. That is the highest-value refactor in this repo.

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

The architecture uses **four root directories** plus root-level entry files.
Adopt incrementally — when you touch a feature, move its pieces to their home.

```
quickshell/
├── shell.qml                     # composition root
├── AGENTS.md
├── justfile
├── domain/
│   ├── models/                   # pure data shapes
│   ├── ports/                    # *Port.qml contracts
│   ├── workflows/                # pure orchestrators
│   ├── constants/                # static business constants
│   └── errors/
├── infra/
│   └── config/                   # Theme.qml, Config.qml (env)
├── adapters/
│   ├── driven/<system>/          # lowercase: service bindings (pipewire, upower, …)
│   └── driving/<Feature>/        # PascalCase: views/panels (Bar, ControlCenter, Menus)
├── tests/
│   ├── contract/                 # one per adapter
│   ├── unit/                     # pure domain + workflows
│   └── fixtures/                 # fakes, builders, sample data
└── build/                        # gitignored, recreatable, never committed
```

| Current file | Destination |
|--------------|-------------|
| `shell.qml` | stay — composition root |
| `Shared/Theme.qml` | `infra/config/Theme.qml` |
| `Shared/NotificationBridge.qml` | `domain/ports/NotificationFeedPort.qml` + `adapters/driven/notifications/` |
| `Shared/Card·Pill·Slider·Overlay.qml` | `adapters/driving/Shared/` |
| `Bar/*.qml` | `adapters/driving/Bar/*`; service reads → `adapters/driven/*` |
| `ControlCenter/ControlCenter.qml` | `adapters/driving/ControlCenter/`; nmcli/bt/brightness/gammastep logic → driven adapters; parsing/math → `domain/` |
| `Menus/Menu.qml` | `adapters/driving/Menus/`; scan+tokenize → `domain/` + `adapters/driven/desktop-entries/` |
| `Menus/Clipboard.qml` | view in `adapters/driving/Menus/`; history/validation → `domain/` |
| `Menus/Wallpapers.qml` | view + `adapters/driven/hyprland/`; selection math → `domain/` |

**File placement decision tree** — every new file lands in one of the four roots:

```
Is it an entry point?              → root file (e.g. shell.qml)
Is it a contract/interface?        → domain/ports/
Is it a pure data shape?           → domain/models/
Is it workflow orchestration?      → domain/workflows/
Is it a constant / error?          → domain/constants/ · domain/errors/
Is it a portable adapter?          → adapters/<driven|driving>/<system>/
Is it config or cross-cutting?     → infra/
Is it a test?                      → tests/
Otherwise: it belongs inside an existing file — do NOT add a fifth root directory.
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
| Architecture / plumbing directories (**smaller imports**) | `lowercase` | `domain/`, `infra/`, `ports/`, `adapters/`, `tests/` |
| `qmldir` module URIs | `lowercase` | `module shared` |
| `id`s, properties, functions, signals, JS files (**smaller imports**) | `lowerCamelCase` | `id: root`, `barVisible`, `setVolume`, `tune.js` |
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
3. **Never import a concrete adapter outside `shell.qml`/`tests/`.** If a view needs a capability, inject a port.
4. **The DTO boundary is real.** Adapters translate service/CLI/D-Bus shapes into domain values. No raw `UPowerDevice`, `Network`, or process output leaks into domain or views.
5. **Views don't do I/O.** No `Process`, `FileView`, `execDetached`, or service imports in `adapters/driving/`. Emit intents; the port acts.
6. **Composition root is the only wiring point.** Only it reads config and constructs adapters. It contains no logic.
7. **No magic numbers in domain.** Name them in `domain/constants/`. Configurable values come from `infra/config`.
8. **Prefer typed service adapters over shell-outs.** Use `Quickshell.Bluetooth`, `Networking`, `Services.Pipewire`, `Services.UPower`, `Hyprland`, `Services.SystemTray`, `Services.Mpris` where the API exists. Shelling out (`nmcli`, `bluetoothctl`, `wpctl`, `brightnessctl`) is a fallback adapter only, and lives in exactly one driven adapter.
9. **Every function pure by default.** Extract pure transforms (`tokenizeExec`, `isUsableText`, `timeoutFor`, icon/signal tiering, filters) into pure functions and unit-test them. Impure code is only the thin I/O methods in adapters and the wiring in `shell.qml`.
10. **Workflows read like pseudocode.** One intent per line: validate → act → report.
11. **Fail fast, never fail silent.** Validate at the boundary; surface errors through `LoggerPort`; handle `onExited` non-zero codes explicitly. No empty `catch`, no `|| true` hidden behind a view.
12. **TimePort / LifetimePort equivalents.** Use a `ClockPort` (backed by `SystemClock`) instead of scattered `Date.now()`, and a `LifetimePort` (backed by `Component.onDestruction` / shell shutdown) to stop processes/timers and flush state on reload/exit.
13. **Portable adapters.** An adapter file copies to another project with only its driver + standard ports: no app imports, config injected, vendor errors translated, mapping pure.
14. **Keep it shippable.** Don't big-bang refactor. Extracting one adapter/port at a time is a complete change; migrate the touched feature and leave the rest.
15. **Reproducible.** No global RNG/time in domain; inject `ClockPort`. Pin no hidden state in singletons beyond config/logging.

---

## 8. Quickshell API surface (what maps where)

| Module (`import`) | Used for | Adapter location |
|-------------------|----------|------------------|
| `Quickshell` | `ShellRoot`, `PanelWindow`, `Variants`, `IpcHandler`, `Quickshell.screens/env/execDetached`, `SystemClock`, `ScriptModel` | root + driving adapters |
| `Quickshell.Io` | `Process`, `SplitParser`, `StdioCollector`, `FileView` | driven adapters only |
| `Quickshell.Services.Pipewire` | audio sinks/sources, volume | `adapters/driven/pipewire/` |
| `Quickshell.Services.UPower` | battery, power profiles | `adapters/driven/upower/` |
| `Quickshell.Services.Notifications` | `NotificationServer`, urgency | `adapters/driven/notifications/` |
| `Quickshell.Networking` | Wi-Fi/Ethernet state | `adapters/driven/network/` |
| `Quickshell.Bluetooth` | adapter/devices/pairing | `adapters/driven/bluetooth/` |
| `Quickshell.Hyprland` | workspaces, dispatch | `adapters/driven/hyprland/` |
| `Quickshell.Services.SystemTray` | tray items/menus | `adapters/driven/system-tray/` |
| `Quickshell.Services.Mpris` | media players | `adapters/driven/mpris/` |
| `Quickshell.Wayland` | layer-shell namespace/focus | driving adapters |
| `Quickshell.Io` + `Process` | brightnessctl, gammastep, wl-clipboard, ls | one driven adapter per tool |

Reference: <https://quickshell.org/docs/v0.3.0/types/>

---

## 9. Testing

- Framework: QtQuickTest (`TestCase`, `SignalSpy`). Run with `qmltestrunner`.
- `tests/unit/` — pure functions and workflows with **fake ports** from `tests/fixtures/`.
  These are fast and must be exhaustive for `domain/`.
- `tests/contract/` — instantiate each adapter and assert the port surface + semantics.
  Run the same contract test against the port's null default and every real adapter.
- `tests/fixtures/` — `FakeAudioPort.qml`, `FakeBatteryPort.qml`, app-entry builders,
  clipboard samples. Shared, never duplicated per test.
- `just verify` = lint + all tiers. Nothing merges unless it is green.
- Every failure path in a driven adapter gets a fault-injection test (non-zero exit,
  missing device, malformed output).

---

## 10. Error handling & diagnostics

- A failure is a domain error with a stable `code`, structured `context`, and a
  preserved `cause` — not a bare string and not a raw service error.
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
- Coupling `Theme` (config) to behavior logic.

---

## 12. New-feature checklist

```
Adding or changing a capability?
├─ Name the contract first: write/extend domain/ports/<Capability>Port.qml
├─ Add static constants to domain/constants/ (no magic numbers)
├─ Extract pure logic into domain/ (models, functions, workflows) + unit tests
├─ Implement the driven adapter under adapters/<driven>/<system>/ (typed service first)
├─ Add tests/contract/<adapter>Test.qml and run it against null + real
├─ Keep the driving view I/O-free: require the port, emit intents
├─ Wire it once in shell.qml (create adapter, inject port)
├─ Register any new error code
├─ Verify: `just run` clean, unit + contract green, no Quickshell imports in domain/
└─ Touch nothing else — the migration is incremental
```

---

## 13. References

- Quickshell types: <https://quickshell.org/docs/v0.3.0/types/>
- Hexagonal architecture (source skill): <https://github.com/shawal-mbalire/shawal_stack/blob/main/hexagonal_architecture.md>
- Architecture diagram: <https://github.com/shawal-mbalire/shawal_stack/blob/main/architecture-diagram.md>
