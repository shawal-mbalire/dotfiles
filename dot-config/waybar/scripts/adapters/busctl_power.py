"""Driven adapter: power-profiles-daemon via ``busctl`` (system bus)."""

from __future__ import annotations

import subprocess


def parse_active_profile(output: str) -> str | None:
    """Parse ``busctl get-property ... ActiveProfile`` output.

    Example: ``'s "balanced"'`` -> ``"balanced"``.
    """
    text = output.strip()
    if not text:
        return None
    if text.startswith("s "):
        text = text[2:].strip()
    text = text.strip('"').strip()
    return text or None


class BusctlPowerGateway:
    def __init__(self, bus: str, path: str, iface: str, command: str = "busctl") -> None:
        self._bus = bus
        self._path = path
        self._iface = iface
        self._command = command

    def get_active(self) -> str | None:
        try:
            result = subprocess.run(
                [
                    self._command,
                    "--system",
                    "get-property",
                    self._bus,
                    self._path,
                    self._iface,
                    "ActiveProfile",
                ],
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError:
            return None
        if result.returncode != 0:
            return None
        return parse_active_profile(result.stdout)

    def set_profile(self, name: str) -> bool:
        try:
            result = subprocess.run(
                [
                    self._command,
                    "--system",
                    "set-property",
                    self._bus,
                    self._path,
                    self._iface,
                    "ActiveProfile",
                    "s",
                    name,
                ],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except OSError:
            return False
        return result.returncode == 0
