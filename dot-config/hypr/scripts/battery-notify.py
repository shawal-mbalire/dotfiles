#!/usr/bin/env python3
"""Battery notifications for waybar + swaync.

Triggers on: low battery (critical/high/normal), charging, full.
Markers re-arm whenever the charging status changes, so each threshold
notifies once per status change instead of on every invocation.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

BATTERY = Path("/sys/class/power_supply/BAT0")
NOTIFY_DIR = Path.home() / ".cache" / "battery-notify"
STATUS_FILE = NOTIFY_DIR / "status"


def read(attribute: str) -> str | None:
    try:
        return (BATTERY / attribute).read_text().strip()
    except OSError:
        return None


def notify(summary: str, body: str, urgency: str, icon: str) -> None:
    subprocess.run(
        ["notify-send", "-a", "battery", "-u", urgency, summary, body, "-i", icon],
        check=False,
    )


def reset_if_status_changed(status: str) -> None:
    NOTIFY_DIR.mkdir(parents=True, exist_ok=True)
    previous = STATUS_FILE.read_text().strip() if STATUS_FILE.exists() else ""
    if previous != status:
        for marker in NOTIFY_DIR.glob("*.sent"):
            marker.unlink(missing_ok=True)
        STATUS_FILE.write_text(status)


def already_sent(name: str) -> bool:
    marker = NOTIFY_DIR / f"{name}.sent"
    if marker.exists():
        return True
    marker.touch()
    return False


def discharging(capacity: int) -> None:
    if capacity <= 3 and not already_sent("3p"):
        notify("Critically Low Battery", f"{capacity}% — plug in now!", "critical", "battery-caution")
    elif capacity <= 10 and not already_sent("10p"):
        notify("Low Battery", f"{capacity}% remaining", "high", "battery-low")
    elif capacity <= 20 and not already_sent("20p"):
        notify("Battery", f"{capacity}% remaining", "normal", "battery-full")


def charging(capacity: int) -> None:
    if capacity >= 100 and not already_sent("100c"):
        notify("Battery Full", "100% — ready to unplug", "low", "battery-full-charged")
    elif capacity >= 80 and not already_sent("80c"):
        notify("Battery", f"{capacity}% — nearing full", "normal", "battery-full")
    elif capacity <= 20 and not already_sent("20c"):
        notify("Charging", f"{capacity}% — still low", "normal", "battery-low")


def full() -> None:
    if not already_sent("full"):
        notify("Battery Full", "100%", "low", "battery-full-charged")


def main() -> int:
    capacity = read("capacity")
    status = read("status")
    if capacity is None or status is None:
        return 0

    try:
        level = int(capacity)
    except ValueError:
        return 0

    reset_if_status_changed(status)

    if status == "Discharging":
        discharging(level)
    elif status == "Charging":
        charging(level)
    elif status == "Full":
        full()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
