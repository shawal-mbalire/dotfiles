#!/usr/bin/env python3
"""Usage: pill-icon.py {clock|temp|network|volume|backlight|battery|bluetooth}

Emits {"text":"<icon>","tooltip":"<detailed>"} so the icon chip and the info
text share ONE detailed tooltip per pill.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from night_light import is_on

K = "<span foreground='#6c7086'>"
V = "<span foreground='#cdd6f4'>"
E = "</span>"
NL = "\n"

BATTERY = Path("/sys/class/power_supply/BAT0")


def run(argv: list[str]) -> str:
    try:
        result = subprocess.run(argv, capture_output=True, text=True, check=False)
    except FileNotFoundError:
        return ""
    return result.stdout.strip()


def succeeds(argv: list[str]) -> bool:
    try:
        return subprocess.run(argv, capture_output=True, check=False).returncode == 0
    except FileNotFoundError:
        return False


def clock() -> tuple[str, str]:
    date = run(["date", "+%A, %B %d, %Y"])
    return "󰥔", f"<span foreground='#fab387' font_weight='bold'>CLOCK{E}{NL}{K}Date{E}  {V}{date}{E}"


def temp() -> tuple[str, str]:
    status = "Active" if is_on() else "Inactive"
    return "󰔏", f"<span foreground='#f5c2e7' font_weight='bold'>GAMMASTEP{E}{NL}{K}Status{E}  {V}{status}{E}"


def network() -> tuple[str, str]:
    route = run(["ip", "route", "get", "1.1.1.1"]).split()
    iface = route[4] if len(route) >= 5 else ""

    ip = ""
    addresses = run(["ip", "-4", "-o", "addr", "show", "scope", "global"]).splitlines()
    if addresses:
        fields = addresses[0].split()
        if len(fields) >= 4:
            ip = fields[3].split("/")[0]

    icon = "󰖩" if iface and succeeds(["iw", "dev", iface, "info"]) else "󰈀"
    tooltip = (
        f"<span foreground='#b4befe' font_weight='bold'>NETWORK{E}{NL}"
        f"{K}Interface{E}  {V}{iface or 'n/a'}{E}{NL}{K}IP{E}  {V}{ip or 'n/a'}{E}"
    )
    return icon, tooltip


def volume() -> tuple[str, str]:
    output = run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    fields = output.split()
    level = "0"
    if len(fields) >= 2:
        try:
            level = str(int(float(fields[1]) * 100))
        except ValueError:
            pass
    mute = "Muted" if "MUTED" in output else "On"
    tooltip = (
        f"<span foreground='#74c7ec' font_weight='bold'>AUDIO{E}{NL}"
        f"{K}Volume{E}  {V}{level}%{E}{NL}{K}Mute{E}  {V}{mute}{E}{NL}"
        f"{K}Left-click{E}  {V}Mute{E}{NL}{K}Right-click{E}  {V}Devices{E}{NL}"
        f"{K}Scroll{E}  {V}Volume{E}"
    )
    return "󰕾", tooltip


def backlight() -> tuple[str, str]:
    fields = run(["brightnessctl", "-m"]).split(",")
    percent = fields[3] if len(fields) >= 4 else "n/a"
    tooltip = (
        f"<span foreground='#f9e2af' font_weight='bold'>BRIGHTNESS{E}{NL}"
        f"{K}Level{E}  {V}{percent}{E}{NL}{K}Scroll{E}  {V}Adjust{E}{NL}"
        f"{K}Right-click{E}  {V}Presets{E}"
    )
    return "󰃞", tooltip


def battery() -> tuple[str, str]:
    try:
        capacity = BATTERY.joinpath("capacity").read_text().strip()
        status = BATTERY.joinpath("status").read_text().strip()
    except OSError:
        capacity, status = "n/a", "Unknown"
    tooltip = (
        f"<span foreground='#a6e3a1' font_weight='bold'>BATTERY{E}{NL}"
        f"{K}Capacity{E}  {V}{capacity}%{E}{NL}{K}Status{E}  {V}{status}{E}"
    )
    return "󰁹", tooltip


def bluetooth() -> tuple[str, str]:
    powered = "On" if "Powered: yes" in run(["bluetoothctl", "show"]) else "Off"
    tooltip = (
        f"<span foreground='#89b4fa' font_weight='bold'>BLUETOOTH{E}{NL}"
        f"{K}Powered{E}  {V}{powered}{E}{NL}{K}Left-click{E}  {V}Devices{E}{NL}"
        f"{K}Right-click{E}  {V}Power toggle{E}"
    )
    return "󰂯", tooltip


MODULES = {
    "clock": clock,
    "temp": temp,
    "network": network,
    "volume": volume,
    "backlight": backlight,
    "battery": battery,
    "bluetooth": bluetooth,
}


def main(argv: list[str]) -> int:
    if len(argv) != 1 or argv[0] not in MODULES:
        print(f"usage: {sys.argv[0]} {{{'|'.join(MODULES)}}}", file=sys.stderr)
        return 1
    icon, tooltip = MODULES[argv[0]]()
    print(json.dumps({"text": icon, "tooltip": tooltip}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
