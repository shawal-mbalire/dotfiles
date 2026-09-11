"""Night-light (gammastep) workflow."""

from __future__ import annotations

from domain.ports.core import Logger, Notifier
from domain.ports.system import NightLightGateway


def toggle(
    gateway: NightLightGateway,
    notifier: Notifier,
    logger: Logger,
    temperature: str,
) -> None:
    if not gateway.is_available():
        notifier.notify("Gammastep", "Error: gammastep not found", "critical")
        return

    if gateway.is_active():
        gateway.disable()
        notifier.notify("Gammastep", "Disabled")
        logger.info("night light disabled")
    else:
        gateway.enable()
        notifier.notify("Gammastep", f"Enabled ({temperature}K)")
        logger.info("night light enabled")
