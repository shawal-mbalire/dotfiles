"""Static domain constants: business knowledge that never changes per machine.

Deployment-specific values (battery supply name, notification app, log level)
are injected from ``infra.config`` instead.
"""

from __future__ import annotations

from domain.models import BatteryNotification

# ── Display toggle ──────────────────────────────────────────────────────────
# Laptop panels are reported as eDP-*; anything else is treated as secondary.
PRIMARY_MONITOR_PREFIX = "eDP"
DEFAULT_PRIMARY_WIDTH = 1920
DISPLAY_MODE = "highres"
MIRROR_POSITION = "0x0"

# ── Battery thresholds (percent) ────────────────────────────────────────────
BATTERY_CRITICAL_PERCENT = 3
BATTERY_LOW_PERCENT = 10
BATTERY_WARN_PERCENT = 20
BATTERY_HIGH_PERCENT = 80
BATTERY_FULL_PERCENT = 100

# ── Battery notifications (static presentation + stable markers) ────────────
DISCHARGING_CRITICAL = BatteryNotification(
    marker="3p",
    summary="Critically Low Battery",
    body_template="{capacity}% — plug in now!",
    urgency="critical",
    icon="battery-caution",
)
DISCHARGING_LOW = BatteryNotification(
    marker="10p",
    summary="Low Battery",
    body_template="{capacity}% remaining",
    urgency="high",
    icon="battery-low",
)
DISCHARGING_WARN = BatteryNotification(
    marker="20p",
    summary="Battery",
    body_template="{capacity}% remaining",
    urgency="normal",
    icon="battery-full",
)
CHARGING_FULL = BatteryNotification(
    marker="100c",
    summary="Battery Full",
    body_template="100% — ready to unplug",
    urgency="low",
    icon="battery-full-charged",
)
CHARGING_HIGH = BatteryNotification(
    marker="80c",
    summary="Battery",
    body_template="{capacity}% — nearing full",
    urgency="normal",
    icon="battery-full",
)
CHARGING_LOW = BatteryNotification(
    marker="20c",
    summary="Charging",
    body_template="{capacity}% — still low",
    urgency="normal",
    icon="battery-low",
)
FULL = BatteryNotification(
    marker="full",
    summary="Battery Full",
    body_template="100%",
    urgency="low",
    icon="battery-full-charged",
)
