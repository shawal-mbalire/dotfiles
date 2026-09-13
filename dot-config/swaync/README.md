# SwayNC Config (Hexagonal Architecture)

Catppuccin Mocha control center in the waybar pill language. SwayNC itself only
reads static `config.json` and `style.css`, so the hexagon is a **generator**:
the domain owns reusable components (containers, buttons, pills, the palette)
and adapters write swaync's wire formats.

## Structure

```
├── scripts/
│   ├── main.py                 # composition root + CLI (the only entry point)
│   ├── dev.py                  # watch-reload and log streaming
│   ├── domain/                 # pure: models, constants, errors, style, ports, workflows
│   │   ├── models.py           # Color, DesignTokens, CssComponent, Button, Widget, panel config
│   │   ├── constants.py        # widget/panel vocabulary + shared selectors
│   │   ├── errors.py           # SwayncError and friends
│   │   ├── style.py            # reusable CSS builders: chips, info fields, pill buttons, glows
│   │   ├── ports/              # core.py (logger/time/lifetime/commands), artifacts.py, verify.py
│   │   └── workflows/          # config.py, theme.py (compose), generate.py (orchestrate)
│   ├── infra/                  # config.py (palette, tokens, buttons; env read HERE only)
│   │   └── paths.py            # output directory resolution
│   └── adapters/               # swaync_mappings.py (pure), swaync_adapter.py, logger, time, lifetime
├── config.json                 # GENERATED — do not edit by hand
├── style.css                   # GENERATED — do not edit by hand
├── pyproject.toml              # ruff + pytest
├── Justfile                    # generate / run / test / lint / typecheck / check
└── README.md
```

**Dependencies point inward.** The domain never imports an adapter and never
touches the file system; adapters implement the ports and map domain models to
JSON/CSS; `main.py` is the only place that reads config and wires them together.

## Reusable components

The point of the refactor is that nothing is copy-pasted:

- **`domain/models.py`** defines `Button` (`Button.toggle` / `Button.action`),
  `Widget`, a named `Color` palette and `DesignTokens`. The two buttons grids
  share the same `Button` model; the config workflow builds both from one list.
- **`domain/workflows/theme.py`** composes one `StyleSheet` from reusable
  rules. Notification cards, action buttons, close buttons, the volume /
  brightness **two-part pill**, grid chips and MPRIS buttons are each declared
  once and reused across the popup and control center.
- **`domain/style.py`** holds the pill design language primitives —
  `icon_chip`, `info_field`, `pill_button`, `glow`, `gradient` — so a new
  widget inherits the look by calling a builder.

### Pill design language (copied from waybar)

| Token | Value |
|---|---|
| Pill radius | `9px` (card `12px`, inner `7px`) |
| Surface field | `alpha(@surface0, 0.5)` |
| Hairline border | `1px solid alpha(@surface1, 0.6)` |
| Hover border | `alpha(@overlay1, 0.8)` |
| Transition | `background-color/border-color/color 0.18s ease` (subtle) |
| Panel shadow | `0 6px 20px alpha(@crust, 0.35)` (neutral, no coloured glow) |
| Active state | `linear-gradient(135deg, @blue, @sapphire)` + crust text |

The control center **floats**: `panel_padding` (`8px`) plus panel margins round
it off so it never butts against the screen edges. Every module then shares one
`module_margin` (`6px 5px`) and zero padding, which is what gives them all the
same width — GTK has no flex and **ignores percentage `min-width`/`min-height`**,
so equal widths have to come from a shared margin box rather than flexbox.

The volume and backlight widgets use the exact waybar two-part pill: a solid
accent **icon chip** rounded on the outer edge (`9px 0 0 9px`) joined to a
translucent **info field** rounded on the inner edge (`0 9px 9px 0`). The
buttons grid reuses the accent cycle (lavender → blue → pink → …): each chip is
a neutral surface field whose glyph is tinted with its accent, a checked toggle
(`:checked`) fills solid with that accent and crust glyph, off toggles show a
muted `@overlay0` glyph, and hover draws a matching accent border rather than a
glow. It lays out **3 chips per row**: `grid_button_width` (`96px`) pins the
flowbox cell so swaync's non-homogeneous `Gtk.FlowBox` wraps at three, then the
natural chip width fills the row. Chips carry **no inline margin** so the
FlowBox minimum equals the drawn row width (the other modules match it). The
notification list subtree is flattened and its background uses a small negative
inline margin so cards span exactly the same width. `background-image: none` is
set so Adwaita's gradient can't paint over the accent `background-color`.
**Clear All** is a quiet neutral pill (`clear_button_width`, since GTK ignores
`min-width: %`) that only tints red on hover.

Toggle state is driven entirely by each button's `update-command`: toggles start
inactive and are set when the control center opens, so the highlight reflects
reality (e.g. the Night button follows the `gammastep` process, not a stale
default).

The generated `config.json` uses swaync's real widget name **`backlight`** (not
`brightness`), and all toggle commands are written for swaync's own execution
wrapper — it already runs commands through `/bin/sh -c "…"`, so the commands are
not wrapped in a second `sh -c` and avoid double quotes.

## Commands

```sh
just generate   # write config.json + style.css
just run        # generate then reload the running swaync
just reload     # swaync-client -R && swaync-client -rs
just dev        # regenerate on change (inotifywait)
just logs       # journalctl --user -f -t swaync
just test       # unit + integration
just lint       # ruff check
just format     # ruff format
just check      # lint + typecheck + test
```

Always edit the **source** (`scripts/`), never the generated files. `just check`
fails if `config.json` or `style.css` drift from what the code produces.

## Configuration

Environment variables are read once in `scripts/infra/config.py`:

| Variable | Purpose |
|---|---|
| `SWAYNC_OUTPUT_DIR` | Where to write `config.json` / `style.css` (default: config dir) |
| `SWAYNC_SCHEMA` | `$schema` path (default `/etc/xdg/swaync/configSchema.json`) |
| `SWAYNC_LOG_LEVEL` | `debug`, `info`, `warning`, `error` (stderr only) |
| `SWAYNC_POSITION_X` / `SWAYNC_POSITION_Y` | Panel anchor |
| `SWAYNC_NOTIFICATION_WIDTH` | Popup width |
| `SWAYNC_CC_WIDTH` / `SWAYNC_CC_HEIGHT` | Control center size |
| `SWAYNC_TIMEOUT*` | Notification timeouts (seconds) |
| `SWAYNC_VOLUME_ICON` / `SWAYNC_BACKLIGHT_ICON` | Widget glyphs |
| `SWAYNC_RELOAD` | Reload command used by `generate --reload` |

The palette, design tokens, accent cycle and button definitions live at the top
of `infra/config.py`; edit them there to retheme every component at once.
