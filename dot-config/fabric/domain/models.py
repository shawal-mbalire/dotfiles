"""Domain models — pure, immutable value objects.

No framework types cross this boundary. Adapters translate vendor shapes into
these models (the DTO boundary); views render them; workflows transform them.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum

# ── Driven-side readings (adapter → domain) ────────────────────────────────


@dataclass(frozen=True, slots=True)
class Battery:
    present: bool = False
    level: int = 0
    charging: bool = False
    state: str = "Unknown"
    time_text: str = ""


@dataclass(frozen=True, slots=True)
class Audio:
    ready: bool = False
    muted: bool = False
    volume: int = 0


@dataclass(frozen=True, slots=True)
class Brightness:
    available: bool = False
    percent: int = 0


@dataclass(frozen=True, slots=True)
class Bluetooth:
    available: bool = False
    enabled: bool = False
    connected_name: str = ""


@dataclass(frozen=True, slots=True)
class NightLight:
    active: bool = False


@dataclass(frozen=True, slots=True)
class WifiEntry:
    name: str
    signal: int
    secured: bool
    known: bool
    connected: bool


@dataclass(frozen=True, slots=True)
class Network:
    available: bool = False
    wifi_enabled: bool = False
    connected: bool = False
    ssid: str = ""
    strength: float = 0.0
    scanning: bool = False
    networks: tuple[WifiEntry, ...] = ()


@dataclass(frozen=True, slots=True)
class Workspace:
    id: int
    active: bool = False


@dataclass(frozen=True, slots=True)
class WorkspaceState:
    workspaces: tuple[Workspace, ...] = ()
    focused_id: int = 1
    count: int = 10


@dataclass(frozen=True, slots=True)
class AppEntry:
    id: str
    name: str
    generic_name: str = ""
    comment: str = ""
    keywords: tuple[str, ...] = ()
    icon_source: str = ""


@dataclass(frozen=True, slots=True)
class TrayItem:
    id: str
    title: str = ""
    icon: str = ""


class Urgency(StrEnum):
    LOW = "low"
    NORMAL = "normal"
    CRITICAL = "critical"


@dataclass(frozen=True, slots=True)
class NotificationEntry:
    key: int
    app_name: str
    app_icon: str = ""
    image: str = ""
    summary: str = ""
    body: str = ""
    urgency: Urgency = Urgency.NORMAL
    critical: bool = False
    transient: bool = False
    duration_ms: int = 0
    received_at: datetime | None = None


@dataclass(frozen=True, slots=True)
class Clipboard:
    history: tuple[str, ...] = ()
    state: str = "loading"  # "loading" | "ready" | "unavailable"


@dataclass(frozen=True, slots=True)
class Wallpaper:
    wallpapers: tuple[str, ...] = ()
    current: str = ""


@dataclass(frozen=True, slots=True)
class NotificationFeed:
    active: tuple[NotificationEntry, ...] = ()
    history: tuple[NotificationEntry, ...] = ()
    now_ms: float = 0.0


# ── View models (pure, built by workflows, rendered by driving adapters) ────


@dataclass(frozen=True, slots=True)
class Segment:
    """A single bar indicator: one glyph + optional label."""

    key: str
    glyph: str
    label: str
    glyph_color: str
    label_color: str
    visible: bool = True
    max_label_width: int = 0


@dataclass(frozen=True, slots=True)
class WorkspacePill:
    id: int
    active: bool
    occupied: bool
    visible: bool


@dataclass(frozen=True, slots=True)
class ClockSegment:
    date_text: str
    time_text: str
    date_color: str
    time_color: str


@dataclass(frozen=True, slots=True)
class BarModel:
    workspaces: tuple[WorkspacePill, ...]
    tray: tuple[TrayItem, ...]
    clock: ClockSegment
    indicators: tuple[Segment, ...]


@dataclass(frozen=True, slots=True)
class ControlCenterModel:
    battery: Segment
    volume: Segment
    brightness: Segment
    network_status: str
    network_connected: bool
    notifications: tuple[NotificationEntry, ...] = ()
    fields: dict[str, object] = field(default_factory=dict)
