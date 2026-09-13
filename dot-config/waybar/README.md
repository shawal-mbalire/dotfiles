# Waybar Configuration

Catppuccin Mocha themed waybar with pill-style modules and 1px borders.

The modules are driven by one Python CLI (`scripts/main.py`) built with a
hexagonal (ports and adapters) architecture. There are no shell scripts.

## Install Dependencies (Fedora)

```bash
sudo dnf install waybar jetbrains-mono-fonts sono-fonts brightnessctl grimblast wireplumber pipewire-utils
```

### Optional Dependencies

- **Screenshots**: `grimblast` (from AUR or COPR)
- **Terminal**: `kitty`
- **Network**: `network-manager-applet` (for `nm-connection-editor`)
- **Power Management**: `tuned-ppd` (provides the `net.hadess.PowerProfiles` D-Bus service)
- **Bluetooth**: `bluez` + `bluez-tools`
- **Audio**: `pipewire` + `wireplumber` (uses `wpctl`/`pactl`)
- **Menus**: `fuzzel`
- **Night light**: `gammastep`

## Architecture

```
scripts/
├── main.py              # thin entry point (delegates to cli.py)
├── cli.py               # driving adapter: argument parsing + command routing
├── wire.py              # composition root: builds adapters from Config
├── bench.py             # verifies the 50ms poll budget
├── domain/              # pure: models, constants, errors, ports, workflows
│   └── workflows/       # incl. refresh.py (render-all) and cache.py (TTL policy)
├── infra/               # config: env vars and user paths are read only here
│   ├── config.py        # typed settings loaded from the environment
│   └── paths.py         # lightweight XDG path resolution for the poll path
└── adapters/            # plumbing: wpctl, pactl, busctl, sysfs, bluetoothctl...
    └── file_cache.py    # CachePort adapter (TimePort-injected)
```

**Dependencies point inward.** The domain never imports an adapter or an
external command; adapters implement the ports and map external data to domain
models; `main.py` is the only place that reads config and wires them together.
Configurable values (battery name, volume step, waybar signal offsets, gammastep
temperature) are loaded in `infra/config.py` and injected into workflows as
arguments — the domain hardcodes no deployment-specific numbers.

### Why poll commands are tiny

Waybar re-runs each `custom/*` module on an interval (2–60s). Those commands
must return within **50ms**, but a Python interpreter plus the full framework
already costs more than that (interpreter startup alone is ~30ms here).

So the poll commands do almost nothing: they print a pre-rendered payload from
`$XDG_RUNTIME_DIR/waybar-cache-<uid>/` and, when it is stale, fork a detached
`main.py refresh` process. The full hexagon runs in that refresher; when done,
it signals waybar (RTMIN+5/7/8) so the module updates immediately.

- **Poll path** (`pill`, `power status`, `audio status`, `nightlight status`):
  stdlib only, no framework import, measured at ~31–40ms.
- **Refresh path** (`main.py refresh`): reads slow sources (`wpctl`, `busctl`)
  and fast sources (sysfs `/proc`) once, renders every module, writes the cache.
- **Action path** (`cycle`, `select`, `toggle`, `menu`, volume keys): runs the
  full stack synchronously; these may block on menus/scans.

Run `just test-budget` (or `scripts/bench.py`) to verify the budget.

## Commands

All modules and keybindings call `scripts/main.py`:

| Command | Purpose |
|---|---|
| `main.py pill <clock\|temp\|network\|volume\|backlight\|battery\|bluetooth>` | Icon chip JSON for a pill |
| `main.py nightlight status\|toggle` | Gammastep on/off status and toggle |
| `main.py power status\|pill\|cycle\|select\|set <profile>` | Power-profile module and actions |
| `main.py audio status\|select\|volume <up\|down\|mute>\|tone` | Audio module, device menu, volume keys |
| `main.py brightness up\|down\|menu` | Backlight steps and presets |
| `main.py bluetooth gui\|menu\|power` | Device menu, bluetoothctl, power toggle |
| `main.py refresh` / `warm` | Re-render every module into the cache (internal) |

## Power profile module

The power module replaces waybar's native `power-profiles-daemon` module (which
needs the `net.hadess.PowerProfiles` D-Bus service). The domain owns the profile
rules (order, labels, icons, colours); `busctl` is the driven adapter behind the
`PowerGateway` port, so the backend can be swapped without touching the domain.

## Volume

Volume is shown by the `custom/audio` and `custom/icon-volume` modules. The
`audio` domain workflow clamps to 100% via `wpctl -l 1.0`. Left-click toggles
mute, right-click opens the device selector, scrolling changes volume in 5%
steps, and the keyboard volume keys call `main.py audio volume ...`, which also
plays the feedback tone.

### Loudness boost

The ThinkPad E16 Gen 3 (Conexant SN6140 + `sof-hda-dsp`) reaches its hardware
`Speaker Playback Volume` 0 dB ceiling at 100%, so a PipeWire smart filter adds
a fixed digital gain between apps and the internal Speaker sink:

```
~/.config/pipewire/pipewire.conf.d/10-speaker-boost.conf
```

Tune `"Gain 1"` (`1.0` = 0 dB, `1.41` = +3 dB, `2.0` = +6 dB) and restart:

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## Volume Feedback Tone

The volume keys play a short beep via PipeWire:

```
/usr/share/sounds/alsa/Front_Center.wav
```

Override the file with the `WAYBAR_SOUND` environment variable.

## Configuration

Environment variables (read once in `infra/`):

| Variable | Default | Purpose |
|---|---|---|
| `WAYBAR_TIME_BUDGET_MS` | `50` | Poll budget enforced by `bench.py` |
| `WAYBAR_LOG_LEVEL` | `warning` | `debug`, `info`, `warning`, `error` (stderr only) |
| `WAYBAR_BATTERY` | `BAT0` | Battery sysfs name |
| `WAYBAR_BACKLIGHT_DEVICE` | `intel_backlight` | Backlight sysfs name |
| `WAYBAR_AUDIO_SINK` | `@DEFAULT_AUDIO_SINK@` | wpctl sink |
| `WAYBAR_AUDIO_STRIP` | *(vendor prefix)* | Prefix stripped from sink descriptions |
| `WAYBAR_AUDIO_CODEC` | *(codec name)* | Codec token stripped from sink descriptions |
| `WAYBAR_VOLUME_STEP` | `5` | Volume step percent |
| `WAYBAR_VOLUME_MAX` | `1.0` | Maximum volume (`wpctl -l`) |
| `WAYBAR_GAMMASTEP_TEMPERATURE` | `16000` | Gammastep colour temperature (K) |
| `WAYBAR_NOTIFY_APP` | `waybar` | Notification app name |
| `WAYBAR_NOTIFY_URGENCY` | `normal` | Default notification urgency |
| `WAYBAR_NOTIFY_FAIL_URGENCY` | `critical` | Urgency for failures |
| `WAYBAR_PROMPT_THEME` | *(empty)* | Fuzzel config path |
| `WAYBAR_SOUND` | `/usr/share/sounds/alsa/Front_Center.wav` | Feedback tone |

## Development

```bash
just test          # unit + integration + e2e tests
just test-unit     # fast domain tests
just test-integration  # real adapters/sysfs on this host
just test-e2e      # end-to-end through main.py
just test-budget   # verify the 50ms poll budget
just lint          # ruff
just format        # ruff format
just check         # lint + typecheck + test
just dev           # warm the cache and run the budget check
```

## Reload Waybar

```bash
just restart
```
