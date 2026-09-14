# greet — a Quickshell login greeter

A login screen for `greetd` built on [Quickshell](https://quickshell.org),
reusing the look of `shore`'s session lock so the login screen and the lock
screen are the same surface. Replaces GDM.

```
greetd ──> cage (kiosk compositor) ──> qs -c greet ──> Quickshell.Services.Greetd
   │
   └─ on launch: greetd starts Hyprland (or the picked session)
```

- **greetd** owns the seat, does PAM (`/etc/pam.d/greetd`) and starts the
  session. Quickshell only drives its IPC socket.
- **cage** is the greeter's compositor. `cage -s` exits when the greeter exits,
  which is what hands the seat back to greetd.
- **`greet`** is this Quickshell config: blurred wallpaper, big clock, password
  box and a session picker. Accent colours are derived from the wallpaper with
  `ColorQuantizer`, exactly like `shore`.

## Layout

```
greet/
├── shell.qml              # composition root: fullscreen window + Login port check
├── domain/Theme.qml       # palette (mirrors shore's)
├── infra/Config.qml       # user, wallpaper path, session defaults
├── ports/Verify.qml       # LoginPort contract, asserted at startup
├── adapters/
│   ├── Login.qml          #   LoginPort: greetd state machine (create/respond/launch)
│   ├── Wallpaper.qml      #   resolves the shared wallpaper
│   ├── WallpaperColors.qml#   accent from the wallpaper
│   └── Sessions.qml       #   /usr/share/wayland-sessions
├── ui/
│   └── GreetSurface.qml   # the visual login surface (no service access)
└── setup/
    ├── install.sh         # packages, publish config, wallpaper dir (root)
    ├── test.sh            # run greetd on VT 7, gdm still in charge (root)
    └── switch.sh          # make greetd the display manager (root)
```

Like `shore`, the greeter is a small hexagon: `ui → ports → domain` and
`adapters → domain`. `shell.qml` only wires and verifies the `LoginPort`; the
greetd conversation lives in `adapters/Login.qml`.

## Install

```sh
just install          # or: sudo ./setup/install.sh
```

This installs `greetd` and `cage`, adds the `greetd` user to `video`/`render`,
copies the config to `/etc/xdg/quickshell/greet`, and writes
`/etc/greetd/config.toml`:

```toml
[terminal]
vt = 1

[default_session]
command = "cage -s -- qs -c greet"
user = "greetd"
```

The config is copied rather than symlinked because the greeter runs as the
`greetd` user and cannot traverse `~` (mode 0700). Re-run `just install` after
editing the QML here.

## Test, then switch

A broken greeter means no graphical login, so test on a spare VT first:

```sh
just test                 # runs greetd on VT 7, gdm still in charge
# Ctrl+Alt+F7 to try it, Ctrl+C to stop
just switch               # disable gdm, enable greetd, reboot to apply
```

If it fails after switching, recover from a text console (Ctrl+Alt+F3) with
`sudo systemctl enable --now gdm`.

## Wallpaper

The greeter reads `/var/lib/greetd/wallpaper/current`. `shore` copies its
current wallpaper there on every change (`shore/adapters/Wallpaper.qml`), so the
login screen follows whatever you last set with `SUPER+W`. The directory is
owned by your user and readable by the `greetd` group; nothing needs to expose
`~`.

Set the wallpaper you want by changing it in a session, then the next login
matches. `install.sh` seeds the file once so the very first boot has a
background.

## Configuration

`infra/Config.qml`:

| Value | Meaning |
|---|---|
| `defaultUser` | account offered on the form (greetd authenticates it) |
| `defaultSession` | session preselected by name match (`"Hyprland"`) |
| `wallpaper` | shared wallpaper path |
| `sessionsDir` | where session `.desktop` files are read from |

The session picker appears only when more than one session exists. The choice
applies to that login only; nothing is persisted.

## Notes

- Fingerprint at login works through PAM: `install.sh` installs `fprintd-pam`
  and relies on `system-auth` (authselect) already providing `pam_fprintd`, so
  the greeter offers "touch the reader or type your password". Enroll a finger
  first with `fprintd-enroll`. The greeter shows whatever greetd prompts.
- The password `TextInput` renders echoed responses (e.g. OTP codes) in clear
  only when greetd asks for an echoed response.
