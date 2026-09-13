"""``MonitorGateway`` adapter: monitor discovery and rules via ``hyprctl``.

Hyprland 0.55 uses the Lua runtime; runtime monitor changes go through
``hyprctl eval 'hl.monitor({...})'`` (the legacy ``keyword`` path is removed).
"""

from __future__ import annotations

import json
import subprocess

from domain.models import Monitor, MonitorRule

from adapters import hyprctl_mappings as mappings


class HyprctlMonitors:
    def __init__(self, binary: str = "hyprctl") -> None:
        self._binary = binary

    def list_monitors(self) -> list[Monitor]:
        output = subprocess.run(
            [self._binary, "-j", "monitors"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        return mappings.parse_monitors(json.loads(output))

    def apply(self, rule: MonitorRule) -> None:
        subprocess.run(
            [self._binary, "eval", mappings.rule_to_lua(rule)],
            check=True,
            capture_output=True,
            text=True,
        )
