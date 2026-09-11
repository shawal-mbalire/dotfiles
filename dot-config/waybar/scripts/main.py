#!/usr/bin/python3 -S
"""Waybar helper scripts — composition root.

Poll commands (the modules waybar re-runs on an interval) never import the
framework: they print a pre-rendered payload from a tiny cache and kick off a
detached refresh when it is stale. The hexagon runs in that refresher, where
speed does not matter. Actions (menus, toggles, keybindings) run the full
stack synchronously.

Usage:
  main.py pill <clock|temp|network|volume|backlight|battery|bluetooth>
  main.py power <status|pill|cycle|select|set <profile>>
  main.py nightlight <status|toggle>
  main.py audio <status|select|volume <up|down|mute>|tone>
  main.py brightness <up|down|menu>
  main.py bluetooth <gui|menu|power>
  main.py refresh          (internal: re-render every module into the cache)
  main.py warm             (alias for refresh)
"""

from __future__ import annotations

import os
import sys

import cachefile

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
MAIN_PATH = os.path.abspath(__file__)
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

PILLS = ("clock", "temp", "network", "volume", "backlight", "battery", "bluetooth")
FALLBACK_PAYLOAD = '{"text": "—", "tooltip": ""}'

# Cache key and time-to-live for every polled module.
MODULE_TTL_MS: dict[str, int] = {
    "pill-clock": 60_000,
    "pill-temp": 5_000,
    "pill-network": 5_000,
    "pill-volume": 5_000,
    "pill-backlight": 5_000,
    "pill-battery": 5_000,
    "pill-bluetooth": 5_000,
    "nightlight-status": 5_000,
    "audio-status": 2_500,
    "power-status": 30_000,
    "power-pill": 30_000,
}

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
    from infra.paths import cache_dir

    directory = cache_dir()
    payload, age_ms, ttl_ms = cachefile.read(directory, key)
    if payload is None or cachefile.is_stale(age_ms, ttl_ms):
        _spawn_refresh()
    print(payload if payload is not None else FALLBACK_PAYLOAD)
    return 0


# ── Refresh path: runs the full hexagon and caches every module ─────────────


def _render_all(config: object, time: object) -> dict[str, object]:
    from adapters.busctl_power import BusctlPowerGateway
    from adapters.proc_network import ProcNetwork
    from adapters.proc_nightlight import GammaStepNightLight
    from adapters.rfkill_bluetooth import RfkillBluetoothPower
    from adapters.sysfs_backlight import SysfsBacklight
    from adapters.sysfs_battery import SysfsBattery
    from adapters.wpctl_audio import WpctlAudioControl
    from domain.workflows import power as power_wf
    from domain.workflows import status as status_wf

    now = time.now()
    network = ProcNetwork().status()
    battery = SysfsBattery(config.battery_supply).status()
    backlight = SysfsBacklight(config.backlight_device).get_percent()
    nightlight = GammaStepNightLight("gammastep", config.gammastep_temperature).is_active()
    bluetooth = RfkillBluetoothPower().is_powered()
    audio = WpctlAudioControl(config.audio_sink, config.volume_max).get_status()
    profile = power_wf.validate_current(
        BusctlPowerGateway(config.power_bus, config.power_path, config.power_iface).get_active()
    )

    return {
        "pill-clock": status_wf.clock_output(now),
        "pill-temp": status_wf.nightlight_pill(nightlight),
        "pill-network": status_wf.network_pill(network),
        "pill-volume": status_wf.volume_pill(audio),
        "pill-backlight": status_wf.backlight_pill(backlight),
        "pill-battery": status_wf.battery_pill(battery),
        "pill-bluetooth": status_wf.bluetooth_pill(bluetooth),
        "nightlight-status": status_wf.nightlight_status(nightlight),
        "audio-status": status_wf.audio_status_output(audio),
        "power-status": power_wf.status_output(profile),
        "power-pill": power_wf.pill_output(profile),
    }


def cmd_refresh(_args: list[str]) -> int:
    import fcntl

    from adapters.system_time import SystemTime
    from adapters.waybar_bar import WaybarBar
    from adapters.waybar_json import render
    from infra.config import load_config
    from infra.paths import cache_dir

    config = load_config()
    time = SystemTime()
    directory = cache_dir()
    os.makedirs(directory, exist_ok=True)

    lock_path = os.path.join(directory, "refresh.lock")
    with open(lock_path, "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            return 0

        outputs = _render_all(config, time)
        for key, output in outputs.items():
            cachefile.write(directory, key, render(output), MODULE_TTL_MS[key])

        bar = WaybarBar()
        offsets = {config.signal_audio, config.signal_power, config.signal_fast}
        for offset in offsets:
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

    from adapters.busctl_power import BusctlPowerGateway
    from adapters.console_logger import ConsoleLogger
    from adapters.fuzzel_prompt import FuzzelPrompt
    from adapters.notify_send import NotifySend
    from adapters.process_lifetime import ProcessLifetime
    from adapters.system_time import SystemTime
    from adapters.waybar_bar import WaybarBar
    from domain.errors import WaybarError
    from domain.workflows import power as power_wf
    from infra.config import load_config

    config = load_config()
    time = SystemTime()
    logger = ConsoleLogger(config.log_level)
    notifier = NotifySend(config.notify_app, config.notify_urgency)
    bar = WaybarBar()
    gateway = BusctlPowerGateway(config.power_bus, config.power_path, config.power_iface)

    with ProcessLifetime():
        try:
            if mode == "cycle":
                ok = power_wf.cycle(gateway, notifier, bar, logger, time, config.signal_power)
            elif mode == "select":
                prompt = FuzzelPrompt(config.prompt_theme)
                ok = power_wf.select(
                    gateway, prompt, notifier, bar, logger, time, config.signal_power
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
        from adapters.console_logger import ConsoleLogger
        from adapters.notify_send import NotifySend
        from adapters.proc_nightlight import GammaStepNightLight
        from adapters.process_lifetime import ProcessLifetime
        from domain.workflows import nightlight as nightlight_wf
        from infra.config import load_config

        config = load_config()
        logger = ConsoleLogger(config.log_level)
        notifier = NotifySend(config.notify_app, config.notify_urgency)
        gateway = GammaStepNightLight("gammastep", config.gammastep_temperature)
        with ProcessLifetime():
            nightlight_wf.toggle(gateway, notifier, logger, config.gammastep_temperature)
        _spawn_refresh()
        return 0

    print("usage: main.py nightlight {status|toggle}", file=sys.stderr)
    return 1


def cmd_audio(args: list[str]) -> int:
    mode = args[0] if args else "status"
    if ("audio", mode) in POLL_KEYS:
        return _run_poll(POLL_KEYS[("audio", mode)])

    if mode == "select":
        from adapters.console_logger import ConsoleLogger
        from adapters.fuzzel_prompt import FuzzelPrompt
        from adapters.notify_send import NotifySend
        from adapters.pactl_audio import PactlAudioDevices
        from adapters.process_lifetime import ProcessLifetime
        from domain.workflows import audio as audio_wf
        from infra.config import load_config

        config = load_config()
        logger = ConsoleLogger(config.log_level)
        with ProcessLifetime():
            audio_wf.select_device(
                PactlAudioDevices(),
                FuzzelPrompt(config.prompt_theme),
                NotifySend(config.notify_app, config.notify_urgency),
                logger,
            )
        return 0

    if mode == "volume":
        from adapters.console_logger import ConsoleLogger
        from adapters.process_lifetime import ProcessLifetime
        from adapters.pw_play import PwPlay
        from adapters.waybar_bar import WaybarBar
        from adapters.wpctl_audio import WpctlAudioControl
        from domain.workflows import audio as audio_wf
        from infra.config import load_config

        action = args[1] if len(args) > 1 else ""
        if action not in ("up", "down", "mute"):
            print("usage: main.py audio volume {up|down|mute}", file=sys.stderr)
            return 1

        config = load_config()
        logger = ConsoleLogger(config.log_level)
        control = WpctlAudioControl(config.audio_sink, config.volume_max)
        sound = PwPlay()
        bar = WaybarBar()

        with ProcessLifetime():
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
        from adapters.console_logger import ConsoleLogger
        from adapters.pw_play import PwPlay
        from domain.workflows import audio as audio_wf
        from infra.config import load_config

        config = load_config()
        logger = ConsoleLogger(config.log_level)
        audio_wf.play_tone(PwPlay(), config.sound_path, logger)
        return 0

    print("usage: main.py audio {status|select|volume|tone}", file=sys.stderr)
    return 1


def cmd_brightness(args: list[str]) -> int:
    action = args[0] if args else ""
    if action not in ("up", "down", "menu"):
        print("usage: main.py brightness {up|down|menu}", file=sys.stderr)
        return 1

    from adapters.console_logger import ConsoleLogger
    from adapters.fuzzel_prompt import FuzzelPrompt
    from adapters.process_lifetime import ProcessLifetime
    from adapters.sysfs_backlight import SysfsBacklight
    from domain.workflows import brightness as brightness_wf
    from infra.config import load_config

    config = load_config()
    logger = ConsoleLogger(config.log_level)
    gateway = SysfsBacklight(config.backlight_device)

    with ProcessLifetime():
        if action == "menu":
            brightness_wf.choose_preset(gateway, FuzzelPrompt(config.prompt_theme), logger)
        else:
            brightness_wf.adjust(gateway, action, logger)
    return 0


def cmd_bluetooth(args: list[str]) -> int:
    mode = args[0] if args else "gui"

    from adapters.bluetoothctl_gateway import BluetoothctlGateway
    from adapters.console_logger import ConsoleLogger
    from adapters.fuzzel_prompt import FuzzelPrompt
    from adapters.notify_send import NotifySend
    from adapters.process_lifetime import ProcessLifetime
    from domain.workflows import bluetooth as bluetooth_wf
    from infra.config import load_config

    config = load_config()
    logger = ConsoleLogger(config.log_level)
    notifier = NotifySend(config.notify_app, config.notify_urgency)
    gateway = BluetoothctlGateway()

    if mode == "menu":
        if not gateway.is_available():
            print("Error: bluetoothctl not found", file=sys.stderr)
            return 1
        gateway.launch_console()
        return 0

    with ProcessLifetime() as lifetime:
        if mode == "power":
            bluetooth_wf.toggle_power(gateway, notifier, logger)
        elif mode == "gui":
            bluetooth_wf.gui(gateway, FuzzelPrompt(config.prompt_theme), notifier, lifetime, logger)
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


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help", "help"):
        print(__doc__.strip())
        return 0 if len(argv) > 1 else 1

    handler = HANDLERS.get(argv[1])
    if handler is None:
        print(f"Unknown command: {argv[1]}", file=sys.stderr)
        return 1
    return handler(argv[2:])


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
