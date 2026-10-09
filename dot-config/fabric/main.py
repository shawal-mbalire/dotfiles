#!/usr/bin/env python3
"""Fabric — composition root.

Reads config → builds adapters → injects ports → starts a driving adapter.
Entry points read like a shell script; no business logic here.

Modes:
  fabric                 run the real GTK4 + layer-shell shell
  fabric --check         validate wiring (headless, contract checks)
  fabric --render        headless smoke test that prints the bar model
  fabric ipc <command>   send a command to the running shell's control socket
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

from domain.ports import (
    AudioPort,
    BatteryPort,
    BluetoothPort,
    BrightnessPort,
    ClipboardPort,
    ColorSchemePort,
    LaunchPort,
    NetworkPort,
    NightLightPort,
    NotificationFeedPort,
    TrayPort,
    WallpaperPort,
    WorkspacePort,
)
from infra.config import AppConfig, load_config


def _configure_logger(config: AppConfig) -> Any:
    from adapters.driven.system.logger import ConsoleLogger

    return ConsoleLogger()


def _session_bus(config: AppConfig, logger) -> object | None:
    try:
        from adapters.driven.dbus import BusConnection

        bus = BusConnection()
        bus.connect()
        return bus
    except Exception as exc:  # noqa: BLE001
        logger.warning("dbus", "session bus unavailable; using fallback adapters", error=str(exc))
        return None


def build_components(config: AppConfig, logger, clock, random, lifetime) -> dict[str, Any]:
    """Create every adapter, its workflows, and the view model. Returns a bundle."""
    c: dict[str, Any] = {}
    bus = _session_bus(config, logger)
    c["bus"] = bus

    # ── theme / colour scheme ─────────────────────────────────────────────
    try:
        from adapters.driven.colorscheme import GioColorSchemeAdapter

        c["colorscheme"] = GioColorSchemeAdapter(logger=logger)
    except Exception:  # noqa: BLE001
        from adapters.driven.colorscheme import NullColorSchemeAdapter

        c["colorscheme"] = NullColorSchemeAdapter(logger=logger)

    from domain.workflows.theme import ThemeWorkflow

    c["theme"] = ThemeWorkflow(c["colorscheme"], logger)

    # ── workspaces (Hyprland native IPC) ──────────────────────────────────
    from adapters.driven.fallback import UnavailableWorkspaceAdapter
    from adapters.driven.hyprland.workspaces import HyprlandWorkspaceAdapter

    if config.hyprland_signature and config.hyprland_socket and config.hyprland_socket.exists():
        c["workspaces"] = HyprlandWorkspaceAdapter(config.hyprland_socket, count=10, logger=logger)
        c["workspaces"].start()
        lifetime.on_exit(lambda _r, a=c["workspaces"]: a.stop())
    else:
        c["workspaces"] = UnavailableWorkspaceAdapter(logger=logger)

    # ── battery / brightness (sysfs, native) ──────────────────────────────
    from adapters.driven.sysfs import SysfsBatteryAdapter, SysfsBrightnessAdapter

    c["battery"] = SysfsBatteryAdapter(logger=logger)
    c["battery"].start()
    lifetime.on_exit(lambda _r, a=c["battery"]: a.stop())

    device_dir = None
    if config.brightness_device:
        device_dir = Path("/sys/class/backlight") / config.brightness_device
    c["brightness"] = SysfsBrightnessAdapter(device_dir=device_dir, logger=logger)
    c["brightness"].start()
    lifetime.on_exit(lambda _r, a=c["brightness"]: a.stop())

    # ── launcher (desktop entries, native) ────────────────────────────────
    from adapters.driven.desktop_entries import DesktopEntriesLaunchAdapter

    c["launcher"] = DesktopEntriesLaunchAdapter(
        data_home=config.home / ".local/share",
        data_dirs=tuple(Path(p) for p in ("/usr/local/share", "/usr/share")),
        terminal_command=("kitty", "-e"),
        logger=logger,
    )
    c["launcher"].start()

    # ── wallpaper store + native GTK renderer (driving) ───────────────────
    from adapters.driven.wallpaper import DirectoryWallpaperStore

    c["wallpaper_store"] = DirectoryWallpaperStore(config.wallpaper_dir, logger=logger)

    # ── D-Bus backed capabilities, with honest fallbacks ──────────────────
    import importlib

    def dbus_capability(
        fallback,
        module_path: str,
        attr: str,
        key: str,
        **adapter_kwargs,
    ):
        if bus is None:
            return fallback(logger=logger)
        try:
            module = importlib.import_module(module_path)
            adapter = getattr(module, attr)(bus, logger=logger, **adapter_kwargs)
            adapter.start()
            lifetime.on_exit(lambda _r, a=adapter: a.stop())
            return adapter
        except Exception as exc:  # noqa: BLE001 - degrade, never crash the shell
            logger.warning("dbus", f"{attr} unavailable; using fallback", error=repr(exc))
            return fallback(logger=logger)

    from adapters.driven.fallback import (
        UnavailableBluetoothAdapter,
        UnavailableNetworkAdapter,
        UnavailableNotificationFeedAdapter,
    )

    c["network"] = dbus_capability(
        UnavailableNetworkAdapter, "adapters.driven.network.nm", "NetworkManagerAdapter", "network"
    )
    c["bluetooth"] = dbus_capability(
        UnavailableBluetoothAdapter, "adapters.driven.bluetooth.bluez", "BluezAdapter", "bluetooth"
    )
    c["notifications"] = dbus_capability(
        UnavailableNotificationFeedAdapter,
        "adapters.driven.notifications.server",
        "NotificationServerAdapter",
        "notifications",
        clock=clock,
    )

    # ── capabilities without a native binding yet (honest degradation) ────
    from adapters.driven.fallback import (
        UnavailableAudioAdapter,
        UnavailableClipboardAdapter,
        UnavailableNightLightAdapter,
        UnavailableTrayAdapter,
    )

    c["audio"] = UnavailableAudioAdapter(logger=logger)
    c["clipboard"] = UnavailableClipboardAdapter(logger=logger)
    c["nightlight"] = UnavailableNightLightAdapter(logger=logger)
    c["tray"] = UnavailableTrayAdapter(logger=logger)

    # ── workflows ─────────────────────────────────────────────────────────
    from domain.workflows import (
        BluetoothWorkflow,
        BrightnessWorkflow,
        ClipboardWorkflow,
        LauncherWorkflow,
        NetworkWorkflow,
        NightLightWorkflow,
        VolumeWorkflow,
        WallpaperWorkflow,
    )

    c["volume"] = VolumeWorkflow(c["audio"], logger)
    c["brightness_wf"] = BrightnessWorkflow(c["brightness"], logger)
    c["nightlight_wf"] = NightLightWorkflow(c["nightlight"], logger)
    c["bluetooth_wf"] = BluetoothWorkflow(c["bluetooth"], logger)
    c["network_wf"] = NetworkWorkflow(c["network"], logger)
    c["launcher_wf"] = LauncherWorkflow(c["launcher"], logger)
    c["clipboard_wf"] = ClipboardWorkflow(c["clipboard"], logger)
    c["wallpaper_wf"] = WallpaperWorkflow(c["wallpaper_store"], random, logger)

    # ── view model ────────────────────────────────────────────────────────
    from adapters.driving.view_model import ShellViewModel

    c["vm"] = ShellViewModel(
        theme=c["theme"],
        clock=clock,
        workspaces=c["workspaces"],
        tray=c["tray"],
        nightlight=c["nightlight"],
        network=c["network"],
        bluetooth=c["bluetooth"],
        audio=c["audio"],
        brightness=c["brightness"],
        battery=c["battery"],
        notifications=c["notifications"],
    )
    return c


# ── modes ──────────────────────────────────────────────────────────────────


def run_check(config: AppConfig, components: dict[str, Any]) -> int:
    # (component key → port protocol)
    contract = {
        "audio": (components["audio"], AudioPort),
        "battery": (components["battery"], BatteryPort),
        "bluetooth": (components["bluetooth"], BluetoothPort),
        "brightness": (components["brightness"], BrightnessPort),
        "clipboard": (components["clipboard"], ClipboardPort),
        "launch": (components["launcher"], LaunchPort),
        "network": (components["network"], NetworkPort),
        "nightlight": (components["nightlight"], NightLightPort),
        "notifications": (components["notifications"], NotificationFeedPort),
        "tray": (components["tray"], TrayPort),
        "wallpaper": (components["wallpaper_store"], WallpaperPort),
        "workspaces": (components["workspaces"], WorkspacePort),
    }
    ok = True
    for key, (adapter, protocol) in sorted(contract.items()):
        conforms = isinstance(adapter, protocol)
        status = "OK " if conforms else "MISSING"
        ok = ok and conforms
        print(f"  [{status}] {key:14} {type(adapter).__name__}")
    cs = components["colorscheme"]
    cs_ok = isinstance(cs, ColorSchemePort)
    print(f"  [{'OK ' if cs_ok else 'MISSING'}] {'colorscheme':14} {type(cs).__name__}")
    if not ok:
        print("check: FAILED — some adapters do not satisfy their port contract")
        return 1
    print("check: all adapters satisfy their port contract")
    return 0


def run_render(config: AppConfig, components: dict[str, Any]) -> int:
    from adapters.driving.text.presenter import TextPresenter

    presenter = TextPresenter(components["vm"])
    presenter.run(seconds=3.0, tick_interval=1.0)
    return 0


def run_gtk(config: AppConfig, components: dict[str, Any], logger, lifetime) -> int:
    from adapters.driving.gtk.app import GtkShell
    from adapters.driving.gtk.layer_shell import gtk_available, layer_shell_available

    if not gtk_available() or not layer_shell_available():
        print("fabric: GTK4 + gtk4-layer-shell are required for the live shell.", file=sys.stderr)
        return 2
    shell = GtkShell(
        view_model=components["vm"],
        config=config,
        logger=logger,
        lifetime=lifetime,
        theme=components["theme"],
        volume=components["volume"],
        brightness=components["brightness_wf"],
        nightlight=components["nightlight_wf"],
        bluetooth=components["bluetooth_wf"],
        workspaces=components["workspaces"],
        wifi=components["network_wf"],
        launcher=components["launcher_wf"],
        clipboard_port=components["clipboard"],
        clipboard=components["clipboard_wf"],
        wallpaper_store=components["wallpaper_store"],
        wallpaper=components["wallpaper_wf"],
        control_path=config.runtime_dir / "fabric.sock",
    )
    return shell.run()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="fabric", description="Fabric — a hexagonal Wayland shell in Python"
    )
    parser.add_argument("--check", action="store_true", help="validate wiring headlessly and exit")
    parser.add_argument(
        "--render", action="store_true", help="headless smoke test that prints the bar model"
    )
    parser.add_argument(
        "ipc",
        nargs="?",
        default=None,
        help="send a command to the running shell (e.g. 'toggle bar')",
    )
    args = parser.parse_args(argv)

    try:
        config = load_config()
    except (ValueError, OSError) as exc:
        print(f"fabric: bad config: {exc}", file=sys.stderr)
        return 1

    logger = _configure_logger(config)

    from adapters.driven.system.clock import SystemClock
    from adapters.driven.system.lifetime import ProcessLifetime
    from adapters.driven.system.randomness import SystemRandom

    clock = SystemClock()
    random = SystemRandom()
    lifetime = ProcessLifetime()

    if args.ipc:
        from adapters.driving.gtk.control_socket import send_command

        try:
            reply = send_command(config.runtime_dir / "fabric.sock", args.ipc)
            print(reply)
            return 0
        except OSError as exc:
            print(f"fabric: cannot reach the running shell: {exc}", file=sys.stderr)
            return 1

    components = build_components(config, logger, clock, random, lifetime)

    mode = "gtk"
    if args.check:
        mode = "check"
    elif args.render:
        mode = "render"

    try:
        if mode == "check":
            return run_check(config, components)
        if mode == "render":
            return run_render(config, components)
        return run_gtk(config, components, logger, lifetime)
    finally:
        lifetime.exit()


if __name__ == "__main__":
    raise SystemExit(main())
