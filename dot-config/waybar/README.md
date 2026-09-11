# Waybar Configuration

Catppuccin Mocha themed waybar with pill-style modules and 1px borders.

## Install Dependencies (Fedora)

```bash
sudo dnf install waybar jetbrains-mono-fonts sono-fonts brightnessctl grimblast wireplumber pipewire-utils
```

### Optional Dependencies

- **Screenshots**: `grimblast` (from AUR or COPR)
- **Terminal**: `kitty`
- **Network**: `network-manager-applet` (for `nm-connection-editor`)
- **Power Management**: `tuned-ppd` (uses `tuned-adm` under the hood)
- **Bluetooth**: `bluez` + `bluez-tools`
- **Audio**: `pipewire` + `wireplumber` (uses `wpctl`)

## Scripts

All scripts are in `scripts/`:

| Script | Purpose |
|---|---|
| `power/main.sh` | Power-profile hexagon: `status` (waybar JSON), `cycle`, `select`, `set` |
| `power/domain.sh` | Pure power-profile rules (cycle order, labels, icons) |
| `power/adapters/tuned.sh` | `tuned-adm` backend for the power-profile gateway |
| `power/adapters/notify.sh` | `notify-send` backend |
| `power/adapters/prompt.sh` | rofi selection menu |
| `power/tests/domain_test.sh` | Unit tests for the pure domain |
| `bluetooth.sh` | Bluetooth device menu and power toggle |
| `select-audio-device.sh` | Audio device selector (rofi) |
| `toggle_temp.py` | Toggle gammastep (night light), `NIGHT_TEMP` at the top |
| `temp-status.py` | Gammastep on/off status for waybar / swaync (`--bool`) |
| `night_light.py` | Shared night-light state (one-shot gammastep has no process) |
| `pill-icon.py` | Pill chip icons + shared tooltips |
| `volume-control.sh` | Volume control with feedback tone |
| `volume-tone.sh` | Play volume feedback tone |

### Night light (gammastep)

`toggle_temp.py` uses `gammastep -O` (one-shot) to apply `NIGHT_TEMP` and
`gammastep -x` to reset. Because one-shot mode exits immediately, the on/off
state is persisted to `$XDG_STATE_HOME/gammastep/night` rather than detected by
process name. `temp-status.py` reads that file, so waybar and the swaync Night
toggle (which passes `SWAYNC_TOGGLE_STATE`) stay in sync. The
`gammastep-indicator` autostart was removed since it continuously overwrote the
manual setting.

### Power profile module

The power module is a small hexagonal application instead of waybar's
`power-profiles-daemon` module (which requires the `net.hadess.PowerProfiles`
D-Bus service that isn't present on this machine). The domain (`domain.sh`)
owns the profile rules; `tuned-adm` is the driven adapter behind a port, so the
backend can be swapped without touching the domain. The composition root is
`power/main.sh status`, which waybar polls via the `custom/power` module.

## Volume

Volume is shown by waybar's native `wireplumber` module, capped at 100% via
`max-volume`. Left-click opens the device selector, middle-click toggles mute,
and scrolling changes volume in 5% steps. The keyboard volume keys use
`scripts/volume-control.sh`, which also clamps to 100% with `wpctl -l 1.0`.

### Loudness boost

The ThinkPad E16 Gen 3 (Conexant SN6140 + `sof-hda-dsp`) reaches its hardware
`Speaker Playback Volume` 0 dB ceiling at 100% — there is no analog headroom
left, which is why 100% used to sound weak and pushing past 100% (software
overamplification) sounded better.

To make 100% actually loud, a PipeWire smart filter applies a fixed digital
gain between apps and the internal Speaker sink. The config lives at:

```
~/.config/pipewire/pipewire.conf.d/10-speaker-boost.conf
```

Tune the boost by editing `"Gain 1"` (linear amplitude: `1.0` = 0 dB,
`1.41` = +3 dB, `2.0` = +6 dB), then:

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

The filter only applies to the internal speakers; Bluetooth/HDMI are unaffected.

## Volume Feedback Tone

The volume keys play a short beep using PipeWire. Sound file used:

```
/usr/share/sounds/alsa/Front_Center.wav
```

If the file doesn't exist on your system, check:
- `/usr/share/sounds/alsa/`
- `/usr/share/sounds/freedesktop/`
- `/usr/share/sounds/gnome/`

Update the `SOUND` variable in `scripts/volume-control.sh` to use a different file.

## Reload Waybar

```bash
killall waybar && waybar &
```
