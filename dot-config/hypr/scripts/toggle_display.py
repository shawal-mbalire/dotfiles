#!/usr/bin/env python3
"""Toggle the secondary monitor between mirror and extend mode.

Outputs are discovered from the running compositor; the baseline layout lives
in infra/config.lua. The primary is the eDP panel, the secondary is anything
else.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys


def hyprctl_json(*args: str) -> list[dict]:
    output = subprocess.run(
        ["hyprctl", "-j", *args], check=True, capture_output=True, text=True
    ).stdout
    return json.loads(output)


def notify(summary: str, body: str) -> None:
    if shutil.which("notify-send"):
        subprocess.run(
            ["notify-send", summary, body, "-i", "video-display"], check=False
        )


def main() -> int:
    if shutil.which("hyprctl") is None:
        print("hyprctl not found", file=sys.stderr)
        return 1

    displays = hyprctl_json("monitors")
    primary = next((d for d in displays if d.get("name", "").startswith("eDP")), None)
    secondary = next((d for d in displays if not d.get("name", "").startswith("eDP")), None)

    if primary is None or secondary is None:
        notify("Display", "Secondary display not detected")
        return 1

    primary_name = primary["name"]
    secondary_name = secondary["name"]
    primary_width = primary.get("width") or 1920
    mirrored = str(secondary.get("mirrorOf", "")) == primary_name

    if mirrored:
        target = f"{secondary_name},highres,{primary_width}x0,1"
        notify("Display", f"Mode: Extended (to the right of {primary_name})")
    else:
        target = f"{secondary_name},highres,0x0,1,mirror,{primary_name}"
        notify("Display", f"Mode: Mirrored ({secondary_name} mirrors {primary_name})")

    subprocess.run(["hyprctl", "keyword", "monitor", target], check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
