"""Workflows — pure orchestrators that coordinate pure logic and port calls."""

from __future__ import annotations

from domain.workflows.connectivity import BluetoothWorkflow, NetworkWorkflow
from domain.workflows.desktop import ClipboardWorkflow, LauncherWorkflow, WallpaperWorkflow
from domain.workflows.media import BrightnessWorkflow, NightLightWorkflow, VolumeWorkflow
from domain.workflows.theme import ThemeWorkflow

__all__ = [
    "BluetoothWorkflow",
    "BrightnessWorkflow",
    "ClipboardWorkflow",
    "LauncherWorkflow",
    "NetworkWorkflow",
    "NightLightWorkflow",
    "ThemeWorkflow",
    "VolumeWorkflow",
    "WallpaperWorkflow",
]
