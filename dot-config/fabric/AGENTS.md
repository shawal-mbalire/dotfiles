# AGENTS.md — Fabric (hexagonal Wayland shell in Python)

Guidance for AI agents (and humans) working in this directory. Fabric is a
Python reimplementation of the sibling `../quickshell/` QML config, following
the same Hexagonal Architecture rules. The rules below are the definition of
"correct" for this repo.

---

## 1. What this is

- **Python ≥ 3.11**, stdlib-only for native integrations; GTK4/PyGObject +
  `gtk4-layer-shell` for rendering.
- **Zero extra installations beyond Hyprland + Fabric.** Every capability is
  implemented natively inside the shell (Hyprland IPC, D-Bus, sysfs, GSettings,
  `.desktop` parsing, layer-shell painting). **Never shell out** to
  `hyprctl`, `nmcli`, `brightnessctl`, `wl-clipboard`, `gsettings`, `hyprpaper`,
  `ls`, or anything else.
- Entry point: `main.py` — the **composition root**. Runs as a single
  long-lived GTK process; `--check`/`--render` are headless validation modes.

## 2. Commands

The `justfile` is a thin command index. Never put logic in it.

| Command | What it does |
|---------|--------------|
| `just` / `just run` | Launch the GTK4 shell. |
| `just check` | Headless wiring check: build every adapter, assert port contracts. |
| `just render` | Headless smoke test printing the live bar model. |
| `just verify` | ruff + mypy + architecture guard + unit tests. Must be green. |
| `just test-contract` | Contract tests: every adapter satisfies its port. |

## 3. Architecture

Hexagonal (Ports & Adapters). The **domain is pure** and imports nothing
outward — enforced by `tests/guards/boundaries.py` (run as part of verify).

```
adapters/driving  →  domain (ports · workflows · models · logic)  ←  adapters/driven
      GTK views        ^  adapter code never imported here            native drivers
```

| Hexagonal concept | Here |
|-------------------|------|
| Domain | `domain/` — pure Python. No GTK, no socket, no D-Bus. Imports stdlib + itself only. |
| Port | A `Protocol` in `domain/ports/*.py` with pre/post conditions in the docstring. |
| Driven adapter | `adapters/driven/<system>/` — implements a port natively. |
| Driving adapter | `adapters/driving/gtk/` — renders view models, emits intents via workflows. |
| Infra | `infra/config.py` — the only place env vars are read. |
| Composition root | `main.py` — reads config, builds adapters, injects ports. No logic. |

Readings flow **adapter → model → view model**: driven adapters push domain
models (`domain/models.py`) through an observable (`adapters/driven/observable.py`);
`adapters/driving/view_model.py::ShellViewModel` subscribes to every port and
builds pure view models (`domain/workflows/presentation.py`); views render them.

## 4. Rules

1. **Dependencies point inward.** Domain never imports adapters/infra/GTK.
2. **No magic numbers in domain.** Named in `domain/constants.py`.
3. **Every function pure by default.** Split logic from I/O; logic in `domain/logic.py`.
4. **Workflows return `Result[T]`** (`domain/result.py`) for expected failures;
   defects raise `AppError` (`domain/errors.py`). Compose with `and_then` /
   `map_value` / `pipeline` / `recover` over named steps.
5. **Views don't do I/O.** No sockets, no files, no D-Bus in `adapters/driving/gtk/` —
   render models and call workflows/ports.
6. **Adapters are native.** No `subprocess` for system queries (launching an app
   via `subprocess.Popen` is the sole exception — that *is* the native action).
7. **Degrade, never crash.** Every D-Bus/sysfs adapter handles an absent backend
   with an honest `Unavailable*Adapter` (see `adapters/driven/fallback/`) and, in
   the composition root, per-capability try/except with fallback.
8. **Native wallpaper.** Fabric paints wallpapers itself on layer-shell
   `BACKGROUND` windows (`adapters/driving/gtk/wallpaper.py`). Do not reintroduce
   hyprpaper or a wallpaper CLI.
9. **Observable contract.** `subscribe(listener)` must call the listener
   immediately with the current reading, and return an `unsubscribe` callable.
10. **Files over folders.** One capability per port file; portable adapters copy
    to another project with only stdlib + their driver.
11. **LifetimePort.** Every resource-owning adapter registers `stop()` on the
    `ProcessLifetime`; no resource is left behind.
12. **Keep it shippable.** Incremental: wire a port, add the adapter, add a
    contract test, verify.

## 5. File placement

```
Is it an entry point?           → root (main.py)
Is it a port (Protocol)?        → domain/ports/<capability>.py
Is it a pure transform?         → domain/logic.py
Is it a pure data shape?        → domain/models.py
Is it workflow orchestration?   → domain/workflows/
Is it a constant / error?       → domain/constants.py · domain/errors.py
Is it a driven adapter?         → adapters/driven/<system>/
Is it a driving view?           → adapters/driving/gtk/
Is it config/cross-cutting?     → infra/
Is it a test?                   → tests/{unit,contract,fixtures,guards}/
Otherwise: it belongs in an existing file — never a fifth root directory.
```

## 6. Testing

- `tests/unit/` — pure logic, workflows, and adapter behaviour with fakes
  (`tests/fixtures/`). Fast, headless, exhaustive for `domain/`.
- `tests/contract/` — asserts every adapter/fake satisfies its port (`isinstance`
  against the runtime-checkable `Protocol`), including immediate-subscribe.
- `tests/guards/boundaries.py` — fails if `domain/` imports anything non-stdlib.
- `just verify` must be green before finishing a change.