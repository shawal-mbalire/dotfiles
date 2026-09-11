"""Driven adapter: full Bluetooth control via ``bluetoothctl``.

``parse_devices`` and ``parse_info`` are pure and unit-tested.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import time

from domain.models import BluetoothDevice

_BATTERY_PAREN = re.compile(r"\((\d+)\)")
_BATTERY_HEX = re.compile(r"0x([0-9a-fA-F]+)")


def parse_devices(output: str) -> list[tuple[str, str]]:
    """Parse ``bluetoothctl devices`` into ``(mac, name)`` pairs."""
    devices: list[tuple[str, str]] = []
    for line in output.splitlines():
        parts = line.split(" ", 2)
        if len(parts) == 3 and parts[0] == "Device":
            devices.append((parts[1], parts[2].strip()))
    return devices


def parse_info(output: str) -> dict[str, object]:
    """Parse ``bluetoothctl info <mac>`` for paired/connected/battery."""
    info: dict[str, object] = {"paired": False, "connected": False, "battery": None}
    for line in output.splitlines():
        stripped = line.strip()
        if stripped.startswith("Paired:"):
            info["paired"] = stripped.split(":", 1)[1].strip() == "yes"
        elif stripped.startswith("Connected:"):
            info["connected"] = stripped.split(":", 1)[1].strip() == "yes"
        elif "Battery Percentage:" in stripped:
            info["battery"] = _parse_battery(stripped)
    return info


def _parse_battery(line: str) -> int | None:
    paren = _BATTERY_PAREN.search(line)
    if paren:
        return int(paren.group(1))
    hex_value = _BATTERY_HEX.search(line)
    if hex_value:
        return int(hex_value.group(1), 16)
    return None


class BluetoothctlGateway:
    def is_available(self) -> bool:
        return shutil.which("bluetoothctl") is not None

    def launch_console(self) -> None:
        os.execvp("bluetoothctl", ["bluetoothctl"])

    def _run(self, *args: str) -> str:
        result = subprocess.run(
            ["bluetoothctl", *args],
            capture_output=True,
            text=True,
            check=False,
        )
        return result.stdout

    def is_powered(self) -> bool:
        for line in self._run("show").splitlines():
            if line.strip().startswith("Powered:"):
                return line.split(":", 1)[1].strip() == "yes"
        return False

    def set_power(self, on: bool) -> None:
        self._run("power", "on" if on else "off")

    def list_devices(self) -> list[BluetoothDevice]:
        devices: list[BluetoothDevice] = []
        for mac, name in parse_devices(self._run("devices")):
            info = parse_info(self._run("info", mac))
            devices.append(
                BluetoothDevice(
                    mac=mac,
                    name=name,
                    paired=bool(info["paired"]),
                    connected=bool(info["connected"]),
                    battery_percent=info["battery"],  # type: ignore[arg-type]
                )
            )
        return devices

    def connect(self, mac: str) -> None:
        self._run("connect", mac)

    def disconnect(self, mac: str) -> None:
        self._run("disconnect", mac)

    def pair(self, mac: str) -> None:
        self._run("pair", mac)

    def trust(self, mac: str) -> None:
        self._run("trust", mac)

    def scan(self, seconds: int) -> None:
        self._run("pairable", "on")
        scan = subprocess.Popen(
            ["bluetoothctl", "--", "scan", "on"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        try:
            time.sleep(seconds)
        finally:
            scan.terminate()
            try:
                scan.wait(timeout=2)
            except subprocess.TimeoutExpired:
                scan.kill()
            self._run("scan", "off")
