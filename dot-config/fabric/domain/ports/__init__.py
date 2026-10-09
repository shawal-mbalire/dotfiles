"""Ports — the interfaces the domain defines and adapters implement."""

from __future__ import annotations

from domain.ports.audio import AudioPort
from domain.ports.base import Listener, ObservablePort, Unsubscribe
from domain.ports.battery import BatteryPort
from domain.ports.bluetooth import BluetoothPort
from domain.ports.brightness import BrightnessPort
from domain.ports.clipboard import ClipboardPort
from domain.ports.clock import ClockPort
from domain.ports.colorscheme import ColorSchemePort
from domain.ports.launch import LaunchPort
from domain.ports.lifetime import ExitReason, LifetimePort
from domain.ports.logger import LoggerPort
from domain.ports.network import FailureListener, NetworkPort
from domain.ports.nightlight import NightLightPort
from domain.ports.notifications import NotificationFeedPort
from domain.ports.randomness import RandomPort
from domain.ports.tray import TrayPort
from domain.ports.wallpaper import WallpaperPort
from domain.ports.workspaces import WorkspacePort

__all__ = [
    "AudioPort",
    "BatteryPort",
    "BluetoothPort",
    "BrightnessPort",
    "ClipboardPort",
    "ClockPort",
    "ColorSchemePort",
    "ExitReason",
    "FailureListener",
    "LaunchPort",
    "LifetimePort",
    "Listener",
    "LoggerPort",
    "NetworkPort",
    "NightLightPort",
    "NotificationFeedPort",
    "ObservablePort",
    "RandomPort",
    "TrayPort",
    "Unsubscribe",
    "WallpaperPort",
    "WorkspacePort",
]
