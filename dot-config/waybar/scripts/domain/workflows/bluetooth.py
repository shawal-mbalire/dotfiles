"""Bluetooth workflow: power toggle and the interactive device menu."""

from __future__ import annotations

from domain.constants import (
    BLUETOOTH_SCAN_SECONDS,
    ICON_BLUETOOTH,
    ICON_BT_AVAILABLE,
    ICON_BT_CONNECTED,
)
from domain.models import BluetoothDevice
from domain.ports.bluetooth import BluetoothGateway
from domain.ports.core import LifetimePort, Logger, Notifier, Prompt


def _connected_line(device: BluetoothDevice) -> str:
    return f" {ICON_BT_CONNECTED} {device.label}"


def _available_line(device: BluetoothDevice) -> str:
    return f" {ICON_BT_AVAILABLE} {device.name}"


def toggle_power(gateway: BluetoothGateway, notifier: Notifier, logger: Logger) -> None:
    if not gateway.is_available():
        notifier.notify("Bluetooth", "Error: bluetoothctl not found", "critical")
        return

    if gateway.is_powered():
        gateway.set_power(False)
        notifier.notify("Bluetooth", "Powered off")
        logger.info("bluetooth powered off")
    else:
        gateway.set_power(True)
        notifier.notify("Bluetooth", "Powered on")
        logger.info("bluetooth powered on")


def _build_menu(devices: list[BluetoothDevice]) -> list[str]:
    connected = [device for device in devices if device.connected]
    available = [device for device in devices if device.paired and not device.connected]

    lines: list[str] = []
    if connected:
        lines.append("── Connected ────────────")
        lines.extend(_connected_line(device) for device in connected)
    if available:
        if lines:
            lines.append("")
        lines.append("── Available ────────────")
        lines.extend(_available_line(device) for device in available)
    if not connected and not available:
        lines.extend(["── Paired Devices ───────", "  No paired devices"])

    lines.extend(
        [
            "",
            "── Commands ─────────────",
            f" {ICON_BLUETOOTH} Toggle Power",
            " Scan & Pair New Device",
        ]
    )
    return lines


def _scan_and_pair(
    gateway: BluetoothGateway,
    prompt: Prompt,
    notifier: Notifier,
    logger: Logger,
) -> None:
    notifier.notify("Bluetooth", f"Scanning for {BLUETOOTH_SCAN_SECONDS} seconds...")
    gateway.scan(BLUETOOTH_SCAN_SECONDS)

    unpaired = [device for device in gateway.list_devices() if not device.paired]
    if not unpaired:
        notifier.notify("Bluetooth", "No new devices found")
        return

    chosen = prompt.choose([device.name for device in unpaired], "Pair Device")
    if not chosen:
        return

    device = next((candidate for candidate in unpaired if candidate.name == chosen), None)
    if device is None:
        return

    gateway.pair(device.mac)
    gateway.trust(device.mac)
    gateway.connect(device.mac)
    notifier.notify("Bluetooth", f"Paired & connected: {device.name}")
    logger.info(f"bluetooth paired {device.mac}")


def gui(
    gateway: BluetoothGateway,
    prompt: Prompt,
    notifier: Notifier,
    lifetime: LifetimePort,
    logger: Logger,
) -> None:
    if not gateway.is_available() or not prompt.is_available():
        notifier.notify("Bluetooth", "Error: bluetoothctl or fuzzel not found", "critical")
        return

    if not gateway.is_powered():
        chosen = prompt.choose(
            ["  Bluetooth is OFF", "─────────────────", "  Turn On"], "Bluetooth"
        )
        if chosen and "Turn On" in chosen:
            gateway.set_power(True)
            notifier.notify("Bluetooth", "Powered on")
        return

    devices = gateway.list_devices()
    chosen = prompt.choose(_build_menu(devices), "Bluetooth")
    if not chosen:
        return

    if "Toggle Power" in chosen:
        gateway.set_power(False)
        notifier.notify("Bluetooth", "Powered off")
        return

    if "Scan & Pair" in chosen:
        _scan_and_pair(gateway, prompt, notifier, logger)
        return

    for device in devices:
        if device.connected and _connected_line(device) == chosen:
            gateway.disconnect(device.mac)
            notifier.notify("Bluetooth", f"Disconnected: {device.name}")
            logger.info(f"bluetooth disconnected {device.mac}")
            return
        if device.paired and not device.connected and _available_line(device) == chosen:
            gateway.connect(device.mac)
            notifier.notify("Bluetooth", f"Connected: {device.name}")
            logger.info(f"bluetooth connected {device.mac}")
            return
