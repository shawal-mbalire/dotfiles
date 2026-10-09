# Fabric ↔ Quickshell comparison (as of quickshell `407d200`)

Fabric is a Python reimplementation of `../quickshell/`. This is a feature-by-feature
and architecture-by-architecture comparison against the **current** quickshell
working tree (commit `407d200` — "media/OSD features, collapsible control center,
autohide bar").

Legend for Fabric status:
- ✅ **native + tested** — implemented on a native interface with passing tests
  (note: D-Bus/sysfs adapters can only be *contract*-tested headless)
- 🧪 **written, unverified** — native code written, needs a live Hyprland/D-Bus session to confirm
- 🔌 port exists, adapter is an honest "unavailable" fallback
- ❌ not present yet

## 1. Feature matrix

| Feature | Quickshell (current) | Fabric | Status |
|---|---|---|---|
| Top bar (per monitor) | `PanelWindow` per screen | layer-shell `BarWindow` per monitor | ✅ |
| Workspaces strip | `Bar/Workspaces.qml` (Hyprland IPC, Lua-aware dispatch) | `HyprlandWorkspaceAdapter` + GTK buttons | ✅ |
| System tray | `Bar/SystemTray.qml` (Quickshell SNI) | `TrayPort` exists | 🔌 |
| Clock | `Bar/Clock.qml` (`MMM d` + `HH:mm`) | `ClockPort` + format_clock | ✅ |
| Network (Wi-Fi) | `NetworkingWifiAdapter` (Quickshell typed) | `NetworkManagerAdapter` (D-Bus) | 🧪 |
| Bluetooth | `BluezBluetoothAdapter` (Quickshell typed) | `BluezAdapter` (D-Bus) | 🧪 |
| Volume | `PipewireAudioAdapter` (Pipewire sink) | — (fallback, shows `_`) | 🔌 |
| Brightness | `SysfsBrightnessAdapter` (sysfs + brightnessctl) | `SysfsBrightnessAdapter` (sysfs, optimistic) | ✅ |
| Battery | `UPowerBatteryAdapter` | `SysfsBatteryAdapter` (sysfs capacity + time) | ✅ |
| Night light | `GammastepNightLightAdapter` | — | 🔌 |
| Media / MPRIS | `MprisMediaAdapter` + `MediaPort` (new: title/artist/album/art, transport) | — | ❌ |
| Audible level cue | `PipewireToneAdapter` + `FeedbackPort.playTone` (new) | — | ❌ |
| Volume/Brightness OSD | `Shared/Osd.qml` (new) | — | ❌ |
| Auto-hide bar | `TopEdgeReveal` + `HotCorner` + pin via IPC (new) | — | ❌ |
| App launcher | `Menus/Menu.qml` (fuzzy search) | `AppLauncherWindow` (`AppSearch` scoring) | ✅ |
| Clipboard history | `WlClipboardAdapter` + `Menus/Clipboard.qml` | `ClipboardPort` + window (persistence missing) | 🔌 |
| Control center | full (toggles, volume/brightness sliders, battery, power profiles, **media**, notifications history) | toggles + sliders + status + history model | 🔶 partial |
| Notification daemon | `Notifications` overlay (actions, urgency, timeouts, history) | `NotificationServerAdapter` (D-Bus server) — toast UI missing | 🧪 partial |
| Wallpapers | wired but **broken** (`Wallpapers {}` without port) | `DirectoryWallpaperStore` + **native GTK background renderer** | ✅ |
| Theme / dark mode | gsettings **CLI** + `Theme.qml` tokens | `ThemeWorkflow` + GSettings (Gio, native) + tokens→CSS | ✅ |
| Keybind IPC | `IpcHandler` (bar/menu/clipboard/controlcenter) | control Unix socket (+ wallpaper, quit) | ✅ |

## 2. Port surface

Ports are contracts (Protocols in Python, `*Port.qml` in QML).

| Port | Quickshell | Fabric |
|---|---|---|
| AudioPort | ✅ | ✅ |
| BatteryPort | ✅ | ✅ |
| BluetoothPort | ✅ (live names: `connectedName`) | ✅ |
| BrightnessPort | ✅ (`percent`/`setPercent`) | ✅ |
| ClipboardPort | ✅ | ✅ |
| LaunchPort | ✅ (`apps`, `launch->bool`) | ✅ |
| NetworkPort | ✅ (`ssid`/`strength`, scans) | ✅ |
| NightLightPort | ✅ | ✅ |
| MediaPort | ✅ (new) | ❌ |
| FeedbackPort | ✅ (new) | ❌ |
| NotificationFeedPort | orphaned (PascalCase; daemon lives in view) | ✅ |
| WallpaperPort / WorkspacePort | orphaned (unused) | ✅ (used) |
| Clock / ColorScheme / Logger / Lifetime / Random | concept only, no ports | ✅ |
| TrayPort | use of Quickshell service directly (no port) | ✅ port, ⌛ adapter |

## 3. Architecture & engineering

| Aspect | Quickshell | Fabric |
|---|---|---|
| Writing language | QML + `.js` pure modules | Python 3.11+ |
| Domain purity gate | convention only (AGENTS.md) | **enforced by test** (`tests/guards/boundaries.py`) |
| Tests | `tst_domainModels.qml` (not runnable here — no qmltestrunner) | 78 tests green (`just verify`: ruff+mypy+guard+unit+contract) |
| Static analysis | `qmllint` (not installed) | ruff + mypy (clean) |
| Failures | `Result` shapes not used | `Result[T]` (`Success`/`Failure`) + `AppError` codes |
| Native IPC | Quickshell typed services + CLI shell-outs (`brightnessctl`, `gammastep`, `wl-copy`, `gsettings`) | **zero CLI shell-outs**; stdlib D-Bus client, Hyprland socket, sysfs, Gio |
| Third-party installs | needs Quickshell + external tools | **only Hyprland + Fabric** |
| Wallpaper | relies on external mechanism (broken) | Fabric paints it itself (layer-shell `BACKGROUND`) |

## 4. Paths to parity (highest value first)

1. **MediaPort + MPRIS adapter** — D-Bus client already exists; `org.mpris.MediaPlayer2.*` property reads + transport commands; control-center media card.
2. **FeedbackPort + tone** — the QML side itself uses a `Process`; native-path equivalent is `libpipewire` via ctypes or a short WAV through the sink. Keep the "coalesce/single-shot" semantics.
3. **Volume OSD + auto-hide bar + hot corner** — pure driving-side GTK work (timers, `TopEdgeReveal`/`HotCorner` equivalents over layer-shell/monitor edges).
4. **AudioPort** — ctypes `libpipewire` (default sink: volume/mute, stream events).
5. **Notification toasts** — feed state exists; render `NotificationFeed.active` as GTK overlays with timeout/actions.
6. **ControlCenter expansion** — network list + PSK entry, battery progress, power profiles, media card.
7. **Clipboard & tray & night-light** — GDK clipboard watcher, SNI host over D-Bus, gamma-control via Wayland protocol.

## 5. Where Fabric is already ahead

- **Tests actually run** headless here; quickshell's `just verify` needs tools not installed.
- **No external tools or daemons** for any feature; quickshell shells out to `brightnessctl`/`gammastep`/`wl-clipboard`/`gsettings`.
- **Wallpapers actually work** (native renderer) vs quickshell's unwired `Wallpapers {}`.
- **Color scheme sync is native** (Gio) vs quickshell's `gsettings` CLI monitor processes.
- Structured errors (`AppError` codes) vs ad-hoc `console.warn`.