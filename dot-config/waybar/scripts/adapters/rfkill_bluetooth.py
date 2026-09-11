"""Driven adapter: fast Bluetooth power state from rfkill sysfs."""

from __future__ import annotations

from pathlib import Path

RFKILL_ROOT = Path("/sys/class/rfkill")


def _read(path: Path) -> str | None:
    try:
        return path.read_text().strip()
    except OSError:
        return None


class RfkillBluetoothPower:
    """Read-only view of the controller power state, safe for polling."""

    def __init__(self, root: Path = RFKILL_ROOT) -> None:
        self._root = Path(root)

    def is_powered(self) -> bool:
        for entry in sorted(self._root.glob("rfkill*")):
            if _read(entry / "type") != "bluetooth":
                continue
            return _read(entry / "soft") == "0" and _read(entry / "hard") == "0"
        return False
