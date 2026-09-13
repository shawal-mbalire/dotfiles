"""Display workflow: toggle the secondary monitor between mirror and extend."""

from __future__ import annotations

from domain import constants
from domain.errors import NoSecondaryMonitorError
from domain.models import Monitor, MonitorRule
from domain.ports.core import Logger, Notifier, TimePort
from domain.ports.display import MonitorGateway


def is_primary(monitor: Monitor) -> bool:
    """Laptop panels are eDP-*; everything else is secondary."""
    return monitor.name.startswith(constants.PRIMARY_MONITOR_PREFIX)


def build_toggle_rule(
    primary: Monitor, secondary: Monitor, currently_mirrored: bool
) -> MonitorRule:
    """Pure: the rule that flips the current mode to the opposite one."""
    width = primary.width or constants.DEFAULT_PRIMARY_WIDTH
    if currently_mirrored:
        return MonitorRule(
            output=secondary.name,
            mode=constants.DISPLAY_MODE,
            position=f"{width}x0",
            scale=1,
        )
    return MonitorRule(
        output=secondary.name,
        mode=constants.DISPLAY_MODE,
        position=constants.MIRROR_POSITION,
        scale=1,
        mirror=primary.name,
    )


def toggle_message(primary: Monitor, secondary: Monitor, currently_mirrored: bool) -> str:
    """Pure: the notification body describing the mode we are switching to."""
    if currently_mirrored:
        return f"Mode: Extended (to the right of {primary.name})"
    return f"Mode: Mirrored ({secondary.name} mirrors {primary.name})"


def toggle_display(
    gateway: MonitorGateway,
    notifier: Notifier,
    logger: Logger,
    time: TimePort,
) -> MonitorRule:
    """Flip mirror/extend on the secondary output and notify the user."""
    started = time.now_ms()
    monitors = gateway.list_monitors()

    primary = next((monitor for monitor in monitors if is_primary(monitor)), None)
    secondary = next((monitor for monitor in monitors if not is_primary(monitor)), None)
    if primary is None or secondary is None:
        raise NoSecondaryMonitorError

    currently_mirrored = secondary.mirror_of == primary.name
    rule = build_toggle_rule(primary, secondary, currently_mirrored)
    gateway.apply(rule)
    notifier.notify("Display", toggle_message(primary, secondary, currently_mirrored))
    logger.info(f"display toggled: {rule.mirror or 'extend'} in {time.elapsed_ms(started)}ms")
    return rule
