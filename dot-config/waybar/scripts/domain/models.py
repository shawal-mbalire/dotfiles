"""Pure data structures for the waybar modules.

No imports outside the standard library: the domain must never depend on a
framework, adapter, or external command.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum


class PowerProfileName(StrEnum):
    """Known power-profile identifiers (the adapter-facing names)."""

    POWER_SAVER = "power-saver"
    BALANCED = "balanced"
    PERFORMANCE = "performance"


class Urgency(StrEnum):
    """Notification urgency levels understood by the notifier adapter."""

    NORMAL = "normal"
    CRITICAL = "critical"


class ExitReason(StrEnum):
    """Why a process is ending, so cleanup can be attributed."""

    NORMAL = "normal"
    USER_EXIT = "user_exit"
    CRASH = "crash"
    TIMEOUT = "timeout"
    SHUTDOWN = "shutdown"


@dataclass(frozen=True)
class PowerProfile:
    """Presentation metadata for a single power profile."""

    name: str
    label: str
    icon: str
    css_class: str


@dataclass(frozen=True)
class ModuleOutput:
    """What a waybar custom module prints: text, markup tooltip and css class."""

    text: str
    tooltip: str = ""
    css_class: str = ""


@dataclass(frozen=True)
class AudioSink:
    """A PulseAudio/PipeWire output device."""

    name: str
    description: str
    is_default: bool = False

    @property
    def menu_label(self) -> str:
        return f"{self.description}  ✓" if self.is_default else self.description


@dataclass(frozen=True)
class AudioStatus:
    """Current volume/mute state of the default sink."""

    volume_percent: int
    muted: bool


@dataclass(frozen=True)
class BluetoothDevice:
    """A device known to the bluetooth controller."""

    mac: str
    name: str
    paired: bool = False
    connected: bool = False
    battery_percent: int | None = None

    @property
    def label(self) -> str:
        """Human label, including battery when the device reports it."""
        if self.battery_percent is None:
            return self.name
        return f"{self.name} ({self.battery_percent}%)"


@dataclass(frozen=True)
class BatteryStatus:
    """Battery capacity and charging state, or ``None`` when unavailable."""

    capacity: int | None = None
    state: str | None = None


@dataclass(frozen=True)
class NetworkStatus:
    """Primary network interface, its address and whether it is wireless."""

    interface: str | None = None
    ip_address: str | None = None
    wireless: bool = False


@dataclass(frozen=True)
class BrightnessStatus:
    """Backlight level as a percentage."""

    percent: int
