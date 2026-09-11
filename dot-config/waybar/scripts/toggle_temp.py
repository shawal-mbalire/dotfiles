#!/usr/bin/env python3
"""Toggle the gammastep night-light filter.

Called by waybar with no argument (toggle) or by swaync, which passes the
desired state in SWAYNC_TOGGLE_STATE ("true"/"false").

gammastep `-O` is one-shot (apply and exit), so turning off uses `gammastep -x`
to reset the gamma ramps rather than killing a process.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys

from night_light import NIGHT_TEMP, is_on, set_on


def notify(body: str) -> None:
    if shutil.which("notify-send"):
        subprocess.run(["notify-send", "Gammastep", body], check=False)


def desired_state() -> bool:
    raw = os.environ.get("SWAYNC_TOGGLE_STATE")
    if raw is None:
        return not is_on()
    return raw.strip().lower() == "true"


def main() -> int:
    if shutil.which("gammastep") is None:
        notify("Error: gammastep not found")
        return 1

    on = desired_state()
    if on:
        subprocess.run(["gammastep", "-O", str(NIGHT_TEMP)], check=False)
    else:
        subprocess.run(["gammastep", "-x"], check=False)
    set_on(on)

    notify(f"Enabled ({NIGHT_TEMP}K)" if on else "Disabled")
    print("on" if on else "off")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
