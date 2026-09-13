#!/usr/bin/env python3
"""Toggle the secondary monitor between mirror and extend mode.

Outputs are discovered from the running compositor; the baseline layout lives
in infra/config.lua. The primary is the eDP panel, the secondary is anything
else.

Hyprland 0.55 uses the Lua runtime: monitor changes go through
`hyprctl eval 'hl.monitor({...})'`. The legacy `keyword monitor ...` path was
removed and now fails with "keyword can't work with non-legacy parsers".
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


def monitor_rule(
    primary_name: str, secondary_name: str, primary_width: int, currently_mirrored: bool
) -> dict:
    """Pure: build the Display DTO consumed by hl.monitor (adapter wire shape)."""
    if currently_mirrored:
        return {
            "output": secondary_name,
            "mode": "highres",
            "position": f"{primary_width}x0",
            "scale": 1,
        }
    return {
        "output": secondary_name,
        "mode": "highres",
        "position": "0x0",
        "scale": 1,
        "mirror": primary_name,
    }


def to_lua(rule: dict) -> str:
    """Pure: serialize a flat monitor rule into an `hl.monitor({...})` call."""
    fields = []
    for key, value in rule.items():
        rendered = f'"{value}"' if isinstance(value, str) else value
        fields.append(f"{key} = {rendered}")
    return "hl.monitor({ " + ", ".join(fields) + " })"


def apply_monitor(rule: dict) -> None:
    subprocess.run(["hyprctl", "eval", to_lua(rule)], check=True)


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
    currently_mirrored = str(secondary.get("mirrorOf", "")) == primary_name

    if currently_mirrored:
        notify("Display", f"Mode: Extended (to the right of {primary_name})")
    else:
        notify("Display", f"Mode: Mirrored ({secondary_name} mirrors {primary_name})")

    apply_monitor(
        monitor_rule(primary_name, secondary_name, primary_width, currently_mirrored)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
