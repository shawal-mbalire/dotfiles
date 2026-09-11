#!/usr/bin/env python3
"""Gammastep night-light status.

Default: waybar JSON. With --bool: prints true/false for swaync's toggle
update-command.
"""

from __future__ import annotations

import json
import sys

from night_light import is_on


def main(argv: list[str]) -> int:
    on = is_on()
    if "--bool" in argv:
        print("true" if on else "false")
        return 0

    status = "Active" if on else "Inactive"
    tooltip = (
        "<span foreground=\"#f5c2e7\" font_weight=\"bold\">GAMMASTEP</span>\n"
        "<span foreground=\"#6c7086\">Status</span>  "
        f"<span foreground=\"#cdd6f4\">{status}</span>"
    )
    print(json.dumps({"text": "On" if on else "Off", "tooltip": tooltip}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
