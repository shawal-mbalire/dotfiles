#!/usr/bin/python3
"""Hyprland helper scripts — composition root.

Reads config, creates adapters, verifies them against the domain ports and runs
the requested workflow. Kept thin: it only wires and dispatches.

Usage:
  main.py display-toggle    Flip the secondary monitor between mirror and extend
  main.py battery-notify    Emit the battery threshold notification, if any
"""

# ruff: noqa: E402
# Imports below intentionally follow the sys.path bootstrap so the script is
# importable both as `python scripts/main.py` and as `import main` in tests.

from __future__ import annotations

import os
import sys

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from adapters.console_logger import ConsoleLogger
from adapters.hyprctl_monitors import HyprctlMonitors
from adapters.notify_send import NotifySend
from adapters.process_lifetime import ProcessLifetime
from adapters.sent_marker_store import SentMarkerStore
from adapters.sysfs_battery import SysfsBattery
from adapters.system_time import SystemTime
from infra.config import Config, load_config

from domain import errors
from domain.ports import verify
from domain.workflows import battery as battery_wf
from domain.workflows import display as display_wf


def _wire(config: Config) -> tuple[ConsoleLogger, SystemTime, NotifySend, ProcessLifetime]:
    logger = ConsoleLogger(config.log_level)
    time = SystemTime()
    notifier = NotifySend(config.notify_app)
    lifetime = ProcessLifetime(logger)

    # Fail loud if any adapter drifts from its port contract.
    verify.assert_port(logger, verify.Logger)
    verify.assert_port(time, verify.TimePort)
    verify.assert_port(notifier, verify.Notifier)
    verify.assert_port(lifetime, verify.LifetimePort)

    return logger, time, notifier, lifetime


def cmd_display_toggle(_argv: list[str]) -> int:
    config = load_config()
    logger, time, notifier, lifetime = _wire(config)
    gateway = HyprctlMonitors()
    verify.assert_port(gateway, verify.MonitorGateway)

    with lifetime:
        try:
            display_wf.toggle_display(gateway, notifier, logger, time)
        except errors.NoSecondaryMonitorError as error:
            logger.warning(str(error))
            notifier.notify("Display", str(error))
            return 1
    return 0


def cmd_battery_notify(_argv: list[str]) -> int:
    config = load_config()
    logger, time, notifier, lifetime = _wire(config)
    reader = SysfsBattery(config.battery_supply)
    store = SentMarkerStore(config.marker_dir)
    verify.assert_port(reader, verify.BatteryReader)
    verify.assert_port(store, verify.SentMarkerStore)

    with lifetime:
        battery_wf.notify_battery(reader, store, notifier, logger, time)
    return 0


HANDLERS = {
    "display-toggle": cmd_display_toggle,
    "battery-notify": cmd_battery_notify,
}


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help", "help"):
        print(__doc__.strip())
        return 0 if len(argv) > 1 else 1

    handler = HANDLERS.get(argv[1])
    if handler is None:
        print(f"Unknown command: {argv[1]}", file=sys.stderr)
        return 1

    try:
        return handler(argv[2:])
    except errors.HyprScriptError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
