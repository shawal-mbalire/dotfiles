#!/usr/bin/python3 -S
"""Driving adapter: CLI parsing and command routing for the waybar modules.

Poll commands (the modules waybar re-runs on an interval) never import the full
framework: they print a pre-rendered payload from a tiny cache and kick off a
detached refresh when it is stale. The hexagon runs in that refresher, where
speed does not matter. Actions (menus, toggles, keybindings) run the full stack
synchronously.
"""

from __future__ import annotations

import os
import sys

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
MAIN_PATH = os.path.join(SCRIPTS_DIR, "main.py")
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

PILLS = ("clock", "temp", "network", "volume", "backlight", "battery", "bluetooth")

# Printed by the poll path before the first refresh completes. Kept as a plain
# string so the poll path never imports the JSON renderer.
FALLBACK_PAYLOAD = '{"text": "\u2014", "tooltip": ""}'

USAGE = """Waybar helper scripts.

Usage:
  main.py pill <clock|temp|network|volume|backlight|battery|bluetooth>
  main.py power <status|pill|cycle|select|set <profile>>
  main.py nightlight <status|toggle>
  main.py audio <status|select|volume <up|down|mute>|tone>
  main.py brightness <up|down|menu>
  main.py bluetooth <gui|menu|power>
  main.py refresh          (internal: re-render every module into the cache)
  main.py warm             (alias for refresh)"""

# Maps ``main.py <group> <mode>`` to the cache key the refresh path writes.
POLL_KEYS: dict[tuple[str, str], str] = {
    ("pill", "clock"): "pill-clock",
    ("pill", "temp"): "pill-temp",
    ("pill", "network"): "pill-network",
    ("pill", "volume"): "pill-volume",
    ("pill", "backlight"): "pill-backlight",
    ("pill", "battery"): "pill-battery",
    ("pill", "bluetooth"): "pill-bluetooth",
    ("nightlight", "status"): "nightlight-status",
    ("audio", "status"): "audio-status",
    ("power", "status"): "power-status",
    ("power", "pill"): "power-pill",
}


# ── Poll path: tiny, stdlib-only, well inside the 50ms budget ───────────────


def _spawn_refresh() -> None:
    """Detach a full refresh so the poll command can return immediately."""
    interpreter = sys.executable or "/usr/bin/python3"
    if not hasattr(os, "fork"):
        import subprocess

        subprocess.Popen(
            [interpreter, "-S", MAIN_PATH, "refresh"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        return

    pid = os.fork()
    if pid != 0:
        return
    try:
        os.setsid()
        devnull = os.open(os.devnull, os.O_RDWR)
        os.dup2(devnull, 0)
        os.dup2(devnull, 1)
        os.dup2(devnull, 2)
        os.execv(interpreter, [interpreter, "-S", MAIN_PATH, "refresh"])
    except OSError:
        pass
    os._exit(127)


def _run_poll(key: str) -> int:
    from adapters.file_cache import FileCache
    from adapters.system_time import SystemTime
    from domain.workflows.cache import is_stale
    from infra.paths import cache_dir

    cache = FileCache(cache_dir(), SystemTime())
    payload, age_ms, ttl_ms = cache.read(key)
    if payload is None or is_stale(age_ms, ttl_ms):
        _spawn_refresh()
    print(payload if payload is not None else FALLBACK_PAYLOAD)
    return 0


# ── Refresh path: runs the full hexagon and caches every module ─────────────


def cmd_refresh(_args: list[str]) -> int:
    import fcntl

    import wire
    from adapters.file_cache import FileCache
    from adapters.waybar_json import render
    from domain.constants import MODULE_TTL_MS
    from domain.workflows import power as power_wf
    from domain.workflows import refresh as refresh_wf
    from infra.config import load_config
    from infra.paths import cache_dir

    config = load_config()
    time = wire.build_time()
    directory = cache_dir()
    os.makedirs(directory, exist_ok=True)

    lock_path = os.path.join(directory, "refresh.lock")
    with open(lock_path, "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            return 0

        outputs = refresh_wf.render_all(
            now=time.now(),
            network=wire.build_network().status(),
            battery=wire.build_battery(config).status(),
            backlight_percent=wire.build_backlight(config).get_percent(),
            nightlight_active=wire.build_nightlight(config).is_active(),
            bluetooth_powered=wire.build_bluetooth_power().is_powered(),
            audio=wire.build_audio_control(config).get_status(),
            profile=power_wf.validate_current(wire.build_power_gateway(config).get_active()),
        )

        cache = FileCache(directory, time)
        for key, output in outputs.items():
            cache.write(key, render(output), MODULE_TTL_MS[key])

        bar = wire.build_bar()
        for offset in {config.signal_audio, config.signal_power, config.signal_fast}:
            bar.refresh(offset)
    return 0


# ── Action path: full stack, synchronous, may block on menus ────────────────


def cmd_pill(args: list[str]) -> int:
    if not args or args[0] not in PILLS:
        print(f"usage: main.py pill {{{'|'.join(PILLS)}}}", file=sys.stderr)
        return 1
    return _run_poll(POLL_KEYS[("pill", args[0])])


def cmd_power(args: list[str]) -> int:
    mode = args[0] if args else "status"
    if ("power", mode) in POLL_KEYS:
        return _run_poll(POLL_KEYS[("power", mode)])

    import wire
    from domain.errors import WaybarError
    from domain.workflows import power as power_wf
    from infra.config import load_config

    config = load_config()
    time = wire.build_time()
    logger = wire.build_logger(config)
    notifier = wire.build_notifier(config)
    bar = wire.build_bar()
    gateway = wire.build_power_gateway(config)

    with wire.build_lifetime(logger):
        try:
            if mode == "cycle":
                ok = power_wf.cycle(gateway, notifier, bar, logger, time, config.signal_power)
            elif mode == "select":
                ok = power_wf.select(
                    gateway,
                    wire.build_prompt(config),
                    notifier,
                    bar,
                    logger,
                    time,
                    config.signal_power,
                )
            elif mode == "set":
                if len(args) < 2:
                    print("usage: main.py power set <profile>", file=sys.stderr)
                    return 1
                ok = power_wf.set_profile(
                    args[1], gateway, notifier, bar, logger, time, config.signal_power
                )
            else:
                print("usage: main.py power {status|pill|cycle|select|set}", file=sys.stderr)
                return 1
        except WaybarError as error:
            logger.error(str(error))
            return 1

    _spawn_refresh()
    return 0 if ok else 1


def cmd_nightlight(args: list[str]) -> int:
    mode = args[0] if args else "status"
    if ("nightlight", mode) in POLL_KEYS:
        return _run_poll(POLL_KEYS[("nightlight", mode)])

    if mode == "toggle":
        import wire
        from domain.workflows import nightlight as nightlight_wf
        from infra.config import load_config

        config = load_config()
        logger = wire.build_logger(config)
        with wire.build_lifetime(logger):
            nightlight_wf.toggle(
                wire.build_nightlight(config),
                wire.build_notifier(config),
                logger,
                config.gammastep_temperature,
            )
        _spawn_refresh()
        return 0

    print("usage: main.py nightlight {status|toggle}", file=sys.stderr)
    return 1


def cmd_audio(args: list[str]) -> int:
    mode = args[0] if args else "status"
    if ("audio", mode) in POLL_KEYS:
        return _run_poll(POLL_KEYS[("audio", mode)])

    import wire
    from infra.config import load_config

    config = load_config()
    logger = wire.build_logger(config)

    if mode == "select":
        from domain.workflows import audio as audio_wf

        with wire.build_lifetime(logger):
            audio_wf.select_device(
                wire.build_audio_devices(config),
                wire.build_prompt(config),
                wire.build_notifier(config),
                logger,
            )
        return 0

    if mode == "volume":
        from domain.workflows import audio as audio_wf

        action = args[1] if len(args) > 1 else ""
        if action not in ("up", "down", "mute"):
            print("usage: main.py audio volume {up|down|mute}", file=sys.stderr)
            return 1

        control = wire.build_audio_control(config)
        sound = wire.build_sound()
        bar = wire.build_bar()

        with wire.build_lifetime(logger):
            if action == "mute":
                audio_wf.toggle_mute(
                    control, sound, config.sound_path, bar, logger, config.signal_audio
                )
            else:
                audio_wf.adjust_volume(
                    control,
                    action,
                    config.volume_step,
                    sound,
                    config.sound_path,
                    bar,
                    logger,
                    config.signal_audio,
                )
        _spawn_refresh()
        return 0

    if mode == "tone":
        from domain.workflows import audio as audio_wf

        audio_wf.play_tone(wire.build_sound(), config.sound_path, logger)
        return 0

    print("usage: main.py audio {status|select|volume|tone}", file=sys.stderr)
    return 1


def cmd_brightness(args: list[str]) -> int:
    action = args[0] if args else ""
    if action not in ("up", "down", "menu"):
        print("usage: main.py brightness {up|down|menu}", file=sys.stderr)
        return 1

    import wire
    from domain.workflows import brightness as brightness_wf
    from infra.config import load_config

    config = load_config()
    logger = wire.build_logger(config)
    gateway = wire.build_backlight(config)

    with wire.build_lifetime(logger):
        if action == "menu":
            brightness_wf.choose_preset(gateway, wire.build_prompt(config), logger)
        else:
            brightness_wf.adjust(gateway, action, logger)
    return 0


def cmd_bluetooth(args: list[str]) -> int:
    mode = args[0] if args else "gui"

    import wire
    from domain.workflows import bluetooth as bluetooth_wf
    from infra.config import load_config

    config = load_config()
    logger = wire.build_logger(config)
    notifier = wire.build_notifier(config)
    gateway = wire.build_bluetooth_gateway()

    if mode == "menu":
        if not gateway.is_available():
            print("Error: bluetoothctl not found", file=sys.stderr)
            return 1
        gateway.launch_console()
        return 0

    lifetime = wire.build_lifetime(logger)
    with lifetime:
        if mode == "power":
            bluetooth_wf.toggle_power(gateway, notifier, logger)
        elif mode == "gui":
            bluetooth_wf.gui(gateway, wire.build_prompt(config), notifier, lifetime, logger)
        else:
            print("usage: main.py bluetooth {gui|menu|power}", file=sys.stderr)
            return 1
    return 0


HANDLERS = {
    "pill": cmd_pill,
    "power": cmd_power,
    "nightlight": cmd_nightlight,
    "audio": cmd_audio,
    "brightness": cmd_brightness,
    "bluetooth": cmd_bluetooth,
    "refresh": cmd_refresh,
    "warm": cmd_refresh,
}


def run(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help", "help"):
        print(USAGE)
        return 0 if len(argv) > 1 else 1

    handler = HANDLERS.get(argv[1])
    if handler is None:
        print(f"Unknown command: {argv[1]}", file=sys.stderr)
        return 1
    return handler(argv[2:])
