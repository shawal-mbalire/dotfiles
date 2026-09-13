"""Battery workflow: pick and emit the right threshold notification."""

from __future__ import annotations

from domain import constants
from domain.models import BatteryNotification, BatteryState, BatteryStatus
from domain.ports.battery import BatteryReader, SentMarkerStore
from domain.ports.core import Logger, Notifier, TimePort


def select_notification(status: BatteryStatus) -> BatteryNotification | None:
    """Pure: the single notification a battery state warrants, if any."""
    capacity = status.capacity
    if capacity is None:
        return None

    if status.state == BatteryState.DISCHARGING:
        if capacity <= constants.BATTERY_CRITICAL_PERCENT:
            return constants.DISCHARGING_CRITICAL
        if capacity <= constants.BATTERY_LOW_PERCENT:
            return constants.DISCHARGING_LOW
        if capacity <= constants.BATTERY_WARN_PERCENT:
            return constants.DISCHARGING_WARN
    elif status.state == BatteryState.CHARGING:
        if capacity >= constants.BATTERY_FULL_PERCENT:
            return constants.CHARGING_FULL
        if capacity >= constants.BATTERY_HIGH_PERCENT:
            return constants.CHARGING_HIGH
        if capacity <= constants.BATTERY_WARN_PERCENT:
            return constants.CHARGING_LOW
    elif status.state == BatteryState.FULL:
        return constants.FULL

    return None


def notify_battery(
    reader: BatteryReader,
    store: SentMarkerStore,
    notifier: Notifier,
    logger: Logger,
    time: TimePort,
) -> None:
    """Read the battery and notify once per threshold per charging state."""
    started = time.now_ms()
    status = reader.read()
    if status.capacity is None or status.state is None:
        logger.debug("battery unavailable, nothing to notify")
        return

    store.reset_for_state(status.state)
    notification = select_notification(status)
    if notification is None or not store.claim(notification.marker):
        logger.debug(f"battery {status.capacity}% {status.state}: no notification")
        return

    notifier.notify(
        notification.summary,
        notification.body(status.capacity),
        notification.urgency,
        notification.icon,
    )
    logger.info(f"battery notification {notification.marker} in {time.elapsed_ms(started)}ms")
