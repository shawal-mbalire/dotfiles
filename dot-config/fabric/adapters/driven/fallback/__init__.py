"""Fallback adapters for capabilities without a native binding at runtime."""

from __future__ import annotations

from adapters.driven.fallback.null import (
    UnavailableAudioAdapter,
    UnavailableBluetoothAdapter,
    UnavailableClipboardAdapter,
    UnavailableNetworkAdapter,
    UnavailableNightLightAdapter,
    UnavailableNotificationFeedAdapter,
    UnavailableTrayAdapter,
    UnavailableWallpaperAdapter,
    UnavailableWorkspaceAdapter,
)

__all__ = [
    "UnavailableAudioAdapter",
    "UnavailableBluetoothAdapter",
    "UnavailableClipboardAdapter",
    "UnavailableNetworkAdapter",
    "UnavailableNightLightAdapter",
    "UnavailableNotificationFeedAdapter",
    "UnavailableTrayAdapter",
    "UnavailableWallpaperAdapter",
    "UnavailableWorkspaceAdapter",
]
